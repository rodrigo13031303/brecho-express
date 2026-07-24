WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF
PROMPT Installing CRT_API_PKG...
@@crt_api_pkg.pks
SHOW ERRORS PACKAGE crt_api_pkg
@@crt_api_pkg.pkb
SHOW ERRORS PACKAGE BODY crt_api_pkg
PROMPT CRT_API_PKG installed successfully.
