WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF
PROMPT Installing CRT_RULE_PKG...
@@crt_rule_pkg.pks
SHOW ERRORS PACKAGE crt_rule_pkg
@@crt_rule_pkg.pkb
SHOW ERRORS PACKAGE BODY crt_rule_pkg
PROMPT CRT_RULE_PKG installed successfully.
