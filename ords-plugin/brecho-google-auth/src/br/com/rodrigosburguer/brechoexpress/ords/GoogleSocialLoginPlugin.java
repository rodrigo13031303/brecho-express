package br.com.rodrigosburguer.brechoexpress.ords;

import java.io.IOException;
import java.io.Reader;
import java.sql.CallableStatement;
import java.sql.Clob;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.Set;
import java.util.UUID;

import jakarta.inject.Inject;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import oracle.dbtools.plugin.api.di.annotations.Provides;
import oracle.dbtools.plugin.api.http.annotations.Dispatches;
import oracle.dbtools.plugin.api.http.annotations.PathTemplate;
import oracle.dbtools.plugin.api.json.objects.JSONNode;
import oracle.dbtools.plugin.api.json.objects.JSONObject;
import oracle.dbtools.plugin.api.json.objects.JSONObjects;

@Provides
@Dispatches(@PathTemplate("/api/v1/auth/social/google"))
public final class GoogleSocialLoginPlugin extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final int MAX_BODY_CHARACTERS = 16384;

    private final Connection connection;
    private final JSONObjects json;
    private final GoogleTokenVerifier verifier;

    @Inject
    GoogleSocialLoginPlugin(Connection connection, JSONObjects json) {
        this.connection = connection;
        this.json = json;
        this.verifier = new GoogleTokenVerifier(json);
    }

    @Override
    protected void doPost(
        HttpServletRequest request,
        HttpServletResponse response
    ) throws ServletException, IOException {
        prepareResponse(response);
        String traceId = UUID.randomUUID().toString().replace("-", "");

        try {
            String idToken = requestToken(request);
            Set<String> audiences = GoogleTokenVerifier.audiences(
                configuredValue("GOOGLE_OAUTH_ALLOWED_AUDIENCES")
            );
            Set<String> presenters = GoogleTokenVerifier.audiences(
                configuredValue("GOOGLE_OAUTH_ALLOWED_PRESENTERS")
            );
            GoogleTokenVerifier.VerifiedIdentity identity =
                verifier.verify(idToken, audiences, presenters);

            DatabaseResponse result = authenticate(
                identity,
                clientAddress(request),
                limited(request.getHeader("User-Agent"), 1000)
            );
            response.setStatus(result.statusCode());
            response.setHeader("X-Trace-Id", result.traceId());
            if (result.body() != null) {
                response.getWriter().write(result.body());
            }
        } catch (GoogleTokenVerifier.VerificationException exception) {
            authenticationFailure(response, traceId);
        } catch (BadRequestException exception) {
            badRequest(response, traceId);
        } catch (SQLException exception) {
            rollbackQuietly();
            throw new ServletException(
                "Google social login database call failed.",
                exception
            );
        }
    }

    private String requestToken(HttpServletRequest request)
        throws IOException, BadRequestException {
        String contentType = request.getContentType();
        if (contentType == null
            || !contentType.toLowerCase(java.util.Locale.ROOT)
                .startsWith("application/json")
        ) {
            throw new BadRequestException();
        }

        StringBuilder body = new StringBuilder();
        try (Reader reader = request.getReader()) {
            char[] buffer = new char[2048];
            int count;
            while ((count = reader.read(buffer)) >= 0) {
                body.append(buffer, 0, count);
                if (body.length() > MAX_BODY_CHARACTERS) {
                    throw new BadRequestException();
                }
            }
        }

        JSONNode node;
        try {
            node = json.read(body);
        } catch (RuntimeException exception) {
            throw new BadRequestException();
        }
        if (!(node instanceof JSONObject object)) {
            throw new BadRequestException();
        }

        int properties = 0;
        for (String ignored : object.propertyNames()) {
            properties++;
        }
        Object token = object.get("idToken");
        if (properties != 1 || !(token instanceof String value) || value.isBlank()) {
            throw new BadRequestException();
        }
        return value;
    }

    private String configuredValue(String code) throws SQLException {
        String sql =
            "SELECT BCF_VALUE_TEXT "
                + "FROM BEX_BUSINESS_CONFIGURATION "
                + "WHERE BCF_CODE = ? "
                + "AND BCF_STATUS = 'ACTIVE'";
        try (
            PreparedStatement statement = connection.prepareStatement(sql);
        ) {
            statement.setString(1, code);
            try (ResultSet result = statement.executeQuery()) {
                if (!result.next()) {
                    return null;
                }
                return result.getString(1);
            }
        }
    }

    private DatabaseResponse authenticate(
        GoogleTokenVerifier.VerifiedIdentity identity,
        String ip,
        String userAgent
    ) throws SQLException, IOException {
        String call =
            "BEGIN "
                + "ord_runtime_pkg.begin_anonymous_request; "
                + "? := core_context_pkg.trace_id(); "
                + "acc_social_auth_api_pkg.login_google_verified("
                + "?,?,?,?,?,?,?,?,?); "
                + "ord_runtime_pkg.clear_request_context; "
                + "END;";

        try (CallableStatement statement = connection.prepareCall(call)) {
            statement.registerOutParameter(1, Types.VARCHAR);
            statement.setString(2, identity.issuer());
            statement.setString(3, identity.subject());
            statement.setString(4, identity.email());
            statement.setString(5, identity.emailVerified() ? "Y" : "N");
            statement.setString(6, identity.name());
            statement.setString(7, ip);
            statement.setString(8, userAgent);
            statement.registerOutParameter(9, Types.INTEGER);
            statement.registerOutParameter(10, Types.CLOB);
            statement.execute();

            String traceId = statement.getString(1);
            int status = statement.getInt(9);
            Clob clob = statement.getClob(10);
            return new DatabaseResponse(
                status,
                traceId,
                clob == null ? null : readClob(clob)
            );
        } catch (SQLException exception) {
            clearContextQuietly();
            throw exception;
        }
    }

    private String readClob(Clob clob) throws SQLException, IOException {
        try (Reader reader = clob.getCharacterStream()) {
            StringBuilder value = new StringBuilder();
            char[] buffer = new char[4096];
            int count;
            while ((count = reader.read(buffer)) >= 0) {
                value.append(buffer, 0, count);
            }
            return value.toString();
        } finally {
            clob.free();
        }
    }

    private void clearContextQuietly() {
        try (CallableStatement statement = connection.prepareCall(
            "BEGIN ord_runtime_pkg.clear_request_context; END;"
        )) {
            statement.execute();
        } catch (SQLException ignored) {
            // The original SQL exception remains authoritative.
        }
    }

    private void rollbackQuietly() {
        try {
            connection.rollback();
        } catch (SQLException ignored) {
            // The servlet container will handle the original failure.
        }
    }

    private String clientAddress(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            int comma = forwarded.indexOf(',');
            return limited(
                comma >= 0 ? forwarded.substring(0, comma) : forwarded,
                64
            );
        }
        return limited(request.getRemoteAddr(), 64);
    }

    private String limited(String value, int maximum) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.length() <= maximum
            ? trimmed
            : trimmed.substring(0, maximum);
    }

    private void prepareResponse(HttpServletResponse response) {
        response.setCharacterEncoding("UTF-8");
        response.setContentType("application/json");
        response.setHeader("Cache-Control", "no-store");
    }

    private void badRequest(HttpServletResponse response, String traceId)
        throws IOException {
        error(
            response,
            traceId,
            400,
            "BEX-REQ-002",
            "VALIDATION_ERROR",
            "A requisicao de autenticacao e invalida."
        );
    }

    private void authenticationFailure(
        HttpServletResponse response,
        String traceId
    ) throws IOException {
        error(
            response,
            traceId,
            401,
            "BEX-AUTH-003",
            "AUTHENTICATION_ERROR",
            "Nao foi possivel autenticar com o provedor informado."
        );
    }

    private void error(
        HttpServletResponse response,
        String traceId,
        int status,
        String code,
        String category,
        String message
    ) throws IOException {
        response.setStatus(status);
        response.setHeader("X-Trace-Id", traceId);
        JSONObject error = json.object()
            .add("code", code)
            .add("category", category)
            .add("message", message)
            .add("retryable", false)
            .build();
        JSONObject envelope = json.object()
            .add("success", false)
            .add("traceId", traceId)
            .add("error", error)
            .build();
        json.write(response.getWriter(), envelope);
    }

    private record DatabaseResponse(
        int statusCode,
        String traceId,
        String body
    ) {}

    private static final class BadRequestException extends Exception {
        private static final long serialVersionUID = 1L;
    }
}
