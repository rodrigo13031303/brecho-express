package br.com.rodrigosburguer.brechoexpress.ords;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import jakarta.inject.Inject;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import oracle.dbtools.plugin.api.di.annotations.Provides;
import oracle.dbtools.plugin.api.http.annotations.Dispatches;
import oracle.dbtools.plugin.api.http.annotations.PathTemplate;

/**
 * Compatibility probe for the Brecho Express Google authentication plugin.
 *
 * <p>This endpoint intentionally performs no authentication yet. It proves that
 * ORDS 25.4 discovers the plugin, maps the request to BRECHOEXPRESS and injects
 * the mapped JDBC connection before the production verifier is introduced.</p>
 */
@Provides
@Dispatches(@PathTemplate("/api/v1/auth/social/google/health"))
public final class GoogleAuthPlugin extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private static final String EXPECTED_SCHEMA = "BRECHOEXPRESS";

    private final Connection connection;

    @Inject
    GoogleAuthPlugin(Connection connection) {
        this.connection = connection;
    }

    @Override
    protected void doGet(
        HttpServletRequest request,
        HttpServletResponse response
    ) throws ServletException, IOException {
        response.setCharacterEncoding("UTF-8");
        response.setContentType("application/json");
        response.setHeader("Cache-Control", "no-store");

        try {
            String currentSchema = currentSchema();
            if (!EXPECTED_SCHEMA.equals(currentSchema)) {
                response.setStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
                response.getWriter().write(
                    "{\"success\":false,\"status\":\"SCHEMA_MAPPING_INVALID\"}"
                );
                return;
            }

            response.setStatus(HttpServletResponse.SC_OK);
            response.getWriter().write(
                "{\"success\":true,\"status\":\"READY\","
                    + "\"component\":\"brecho-google-auth-plugin\"}"
            );
        } catch (SQLException exception) {
            throw new ServletException(
                "Unable to validate the ORDS schema mapping.",
                exception
            );
        }
    }

    private String currentSchema() throws SQLException {
        String sql =
            "SELECT SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') FROM DUAL";

        try (
            PreparedStatement statement = connection.prepareStatement(sql);
            ResultSet result = statement.executeQuery()
        ) {
            if (!result.next()) {
                throw new SQLException(
                    "Oracle returned no CURRENT_SCHEMA value."
                );
            }
            return result.getString(1);
        }
    }
}
