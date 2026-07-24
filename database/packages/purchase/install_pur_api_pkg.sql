WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF
PROMPT Installing PUR_API_PKG...
@@pur_api_pkg.pks
SHOW ERRORS PACKAGE pur_api_pkg
@@pur_api_pkg.pkb
SHOW ERRORS PACKAGE BODY pur_api_pkg
PROMPT PUR_API_PKG installed successfully.
