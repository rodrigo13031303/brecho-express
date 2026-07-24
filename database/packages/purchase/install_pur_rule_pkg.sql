WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF
PROMPT Installing PUR_RULE_PKG...
@@pur_rule_pkg.pks
SHOW ERRORS PACKAGE pur_rule_pkg
@@pur_rule_pkg.pkb
SHOW ERRORS PACKAGE BODY pur_rule_pkg
PROMPT PUR_RULE_PKG installed successfully.
