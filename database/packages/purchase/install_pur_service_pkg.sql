WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF
PROMPT Installing PUR_SERVICE_PKG...
@@pur_service_pkg.pks
SHOW ERRORS PACKAGE pur_service_pkg
@@pur_service_pkg.pkb
SHOW ERRORS PACKAGE BODY pur_service_pkg
PROMPT PUR_SERVICE_PKG installed successfully.
