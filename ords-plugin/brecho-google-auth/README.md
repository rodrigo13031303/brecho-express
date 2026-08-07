# Brecho Express Google Auth - ORDS Plugin

Google ID token verifier for Oracle REST Data Services 25.4 and Java 17.

The plugin exposes:

```text
GET /ords/brechoexpress/api/v1/auth/social/google/health
POST /ords/brechoexpress/api/v1/auth/social/google
```

The health endpoint verifies plugin discovery. The login endpoint validates
Google's RS256 signature and token claims before delegating account linking and
session creation to the database domain.

The verified optional `name` claim provisions the initial PROFILE. Existing
user-customized profile names are preserved.

Required active business configurations:

```text
GOOGLE_OAUTH_ALLOWED_AUDIENCES
GOOGLE_OAUTH_ALLOWED_PRESENTERS
```

The audience is the backend Web OAuth client. Presenters are the Android and
iOS OAuth clients accepted in the optional `azp` claim.

## Server build

The server must contain the official ORDS 25.4 plugin libraries under:

```text
/opt/ords/examples/plugins/lib
```

Build:

```bash
chmod +x build.sh
./build.sh
```

The output is:

```text
built/brecho-google-auth.jar
```

Deployment and ORDS restart are separate operational steps.
