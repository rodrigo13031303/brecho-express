WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF
PROMPT Installing PUR_REPOSITORY_PKG...
@@pur_repository_pkg.pks
SHOW ERRORS PACKAGE pur_repository_pkg
@@pur_repository_pkg.pkb
SHOW ERRORS PACKAGE BODY pur_repository_pkg
PROMPT PUR_REPOSITORY_PKG installed successfully.
