SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE

BEGIN
  core_security_context_pkg.clear;
  core_context_pkg.clear;
  core_trace_pkg.clear;
END;
/

@@test_core_trace_pkg.sql
@@test_core_error_pkg.sql
@@test_core_context_pkg.sql
@@test_core_security_context_pkg.sql

BEGIN
  core_security_context_pkg.clear;
  core_context_pkg.clear;
  core_trace_pkg.clear;
  DBMS_OUTPUT.PUT_LINE('SUCCESS - CORE FRAMEWORK TEST SUITE');
EXCEPTION
  WHEN OTHERS THEN
    core_security_context_pkg.clear;
    core_context_pkg.clear;
    core_trace_pkg.clear;
    RAISE;
END;
/

EXIT SUCCESS
