package br.com.rodrigosburguer.brechoexpress.ords;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.PublicKey;
import java.security.Signature;
import java.security.spec.RSAPublicKeySpec;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import oracle.dbtools.plugin.api.json.objects.JSONArray;
import oracle.dbtools.plugin.api.json.objects.JSONNode;
import oracle.dbtools.plugin.api.json.objects.JSONObject;
import oracle.dbtools.plugin.api.json.objects.JSONObjects;

final class GoogleTokenVerifier {
    private static final URI JWKS_URI =
        URI.create("https://www.googleapis.com/oauth2/v3/certs");
    private static final Set<String> ISSUERS = Set.of(
        "accounts.google.com",
        "https://accounts.google.com"
    );
    private static final Pattern MAX_AGE =
        Pattern.compile("(?:^|,)\\s*max-age=(\\d+)", Pattern.CASE_INSENSITIVE);
    private static final Base64.Decoder BASE64_URL = Base64.getUrlDecoder();
    private static final HttpClient HTTP = HttpClient.newBuilder()
        .connectTimeout(Duration.ofSeconds(5))
        .followRedirects(HttpClient.Redirect.NEVER)
        .build();
    private static final Object CACHE_LOCK = new Object();
    private static volatile KeyCache keyCache = new KeyCache(Map.of(), Instant.EPOCH);

    private final JSONObjects json;

    GoogleTokenVerifier(JSONObjects json) {
        this.json = json;
    }

    VerifiedIdentity verify(
        String token,
        Set<String> allowedAudiences,
        Set<String> allowedPresenters
    )
        throws VerificationException {
        if (token == null || token.length() > 8192 || allowedAudiences.isEmpty()) {
            throw new VerificationException();
        }

        String[] parts = token.split("\\.", -1);
        if (parts.length != 3) {
            throw new VerificationException();
        }

        JSONObject header = decodeObject(parts[0]);
        JSONObject claims = decodeObject(parts[1]);
        String algorithm = string(header, "alg", true);
        String keyId = string(header, "kid", true);
        if (!"RS256".equals(algorithm) || keyId.length() > 255) {
            throw new VerificationException();
        }

        PublicKey key = publicKey(keyId);
        verifySignature(parts[0] + "." + parts[1], parts[2], key);

        String issuer = string(claims, "iss", true);
        String subject = string(claims, "sub", true);
        String email = string(claims, "email", false);
        Object emailVerifiedClaim = claims.get("email_verified");
        boolean emailVerified =
            Boolean.TRUE.equals(emailVerifiedClaim)
                || (
                    emailVerifiedClaim instanceof String value
                        && "true".equalsIgnoreCase(value)
                );
        long expiration = integer(claims, "exp");
        long issuedAt = integer(claims, "iat");
        Instant now = Instant.now();

        if (!ISSUERS.contains(issuer)
            || subject.isBlank()
            || subject.length() > 255
            || expiration <= now.minusSeconds(30).getEpochSecond()
            || issuedAt > now.plusSeconds(300).getEpochSecond()
            || !audienceAllowed(claims.get("aud"), allowedAudiences)
        ) {
            throw new VerificationException();
        }

        String authorizedParty = string(claims, "azp", false);
        if (authorizedParty != null
            && !allowedAudiences.contains(authorizedParty)
            && !allowedPresenters.contains(authorizedParty)
        ) {
            throw new VerificationException();
        }

        if (email != null) {
            email = email.trim().toLowerCase(java.util.Locale.ROOT);
            if (email.length() > 255) {
                throw new VerificationException();
            }
        }

        return new VerifiedIdentity(
            issuer,
            subject,
            email,
            emailVerified
        );
    }

    private JSONObject decodeObject(String encoded) throws VerificationException {
        try {
            byte[] decoded = BASE64_URL.decode(encoded);
            if (decoded.length == 0 || decoded.length > 8192) {
                throw new VerificationException();
            }
            JSONNode node = json.read(new String(decoded, StandardCharsets.UTF_8));
            if (!(node instanceof JSONObject object)) {
                throw new VerificationException();
            }
            return object;
        } catch (IllegalArgumentException exception) {
            throw new VerificationException();
        }
    }

    private void verifySignature(
        String signingInput,
        String encodedSignature,
        PublicKey key
    ) throws VerificationException {
        try {
            Signature verifier = Signature.getInstance("SHA256withRSA");
            verifier.initVerify(key);
            verifier.update(signingInput.getBytes(StandardCharsets.US_ASCII));
            if (!verifier.verify(BASE64_URL.decode(encodedSignature))) {
                throw new VerificationException();
            }
        } catch (VerificationException exception) {
            throw exception;
        } catch (Exception exception) {
            throw new VerificationException();
        }
    }

    private PublicKey publicKey(String keyId) throws VerificationException {
        KeyCache current = keyCache;
        if (current.expiresAt().isAfter(Instant.now())
            && current.keys().containsKey(keyId)
        ) {
            return current.keys().get(keyId);
        }

        synchronized (CACHE_LOCK) {
            current = keyCache;
            if (!current.expiresAt().isAfter(Instant.now())
                || !current.keys().containsKey(keyId)
            ) {
                keyCache = fetchKeys();
            }
            PublicKey key = keyCache.keys().get(keyId);
            if (key == null) {
                throw new VerificationException();
            }
            return key;
        }
    }

    private KeyCache fetchKeys() throws VerificationException {
        try {
            HttpRequest request = HttpRequest.newBuilder(JWKS_URI)
                .timeout(Duration.ofSeconds(10))
                .header("Accept", "application/json")
                .header("User-Agent", "BrechoExpress-ORDS-GoogleAuth/1.0")
                .GET()
                .build();
            HttpResponse<String> response = HTTP.send(
                request,
                HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8)
            );
            if (response.statusCode() != 200 || response.body().length() > 65536) {
                throw new VerificationException();
            }

            JSONNode rootNode = json.read(response.body());
            if (!(rootNode instanceof JSONObject root)
                || !(root.get("keys") instanceof JSONArray keysNode)
            ) {
                throw new VerificationException();
            }

            Map<String, PublicKey> keys = new HashMap<>();
            for (Object value : keysNode.values()) {
                if (!(value instanceof JSONObject jwk)
                    || !"RSA".equals(string(jwk, "kty", true))
                    || !"RS256".equals(string(jwk, "alg", true))
                    || !"sig".equals(string(jwk, "use", true))
                ) {
                    continue;
                }
                String kid = string(jwk, "kid", true);
                String modulus = string(jwk, "n", true);
                String exponent = string(jwk, "e", true);
                keys.put(kid, rsaKey(modulus, exponent));
            }
            if (keys.isEmpty()) {
                throw new VerificationException();
            }

            long maxAge = cacheMaxAge(
                response.headers().firstValue("Cache-Control").orElse("")
            );
            return new KeyCache(
                Map.copyOf(keys),
                Instant.now().plusSeconds(maxAge)
            );
        } catch (VerificationException exception) {
            throw exception;
        } catch (Exception exception) {
            throw new VerificationException();
        }
    }

    private PublicKey rsaKey(String modulus, String exponent) throws Exception {
        RSAPublicKeySpec spec = new RSAPublicKeySpec(
            new BigInteger(1, BASE64_URL.decode(modulus)),
            new BigInteger(1, BASE64_URL.decode(exponent))
        );
        return KeyFactory.getInstance("RSA").generatePublic(spec);
    }

    private long cacheMaxAge(String cacheControl) {
        Matcher matcher = MAX_AGE.matcher(cacheControl);
        if (!matcher.find()) {
            return 3600;
        }
        long value;
        try {
            value = Long.parseLong(matcher.group(1));
        } catch (NumberFormatException exception) {
            return 3600;
        }
        return Math.max(60, Math.min(value, 86400));
    }

    private boolean audienceAllowed(Object audience, Set<String> allowed) {
        if (audience instanceof String value) {
            return allowed.contains(value);
        }
        if (audience instanceof JSONArray values) {
            for (Object value : values.values()) {
                if (value instanceof String item && allowed.contains(item)) {
                    return true;
                }
            }
        }
        return false;
    }

    private String string(
        JSONObject object,
        String name,
        boolean required
    ) throws VerificationException {
        Object value = object.get(name);
        if (value == null && !required) {
            return null;
        }
        if (!(value instanceof String text) || (required && text.isBlank())) {
            throw new VerificationException();
        }
        return text;
    }

    private long integer(JSONObject object, String name)
        throws VerificationException {
        Object value = object.get(name);
        if (!(value instanceof BigDecimal number)) {
            throw new VerificationException();
        }
        try {
            return number.longValueExact();
        } catch (ArithmeticException exception) {
            throw new VerificationException();
        }
    }

    static Set<String> audiences(String configured)
        throws VerificationException {
        Set<String> audiences = new HashSet<>();
        if (configured != null) {
            for (String item : configured.split(",")) {
                String value = item.trim();
                if (!value.isEmpty()) {
                    audiences.add(value);
                }
            }
        }
        if (audiences.isEmpty()) {
            throw new VerificationException();
        }
        return Set.copyOf(audiences);
    }

    record VerifiedIdentity(
        String issuer,
        String subject,
        String email,
        boolean emailVerified
    ) {}

    private record KeyCache(Map<String, PublicKey> keys, Instant expiresAt) {}

    static final class VerificationException extends Exception {
        private static final long serialVersionUID = 1L;
    }
}
