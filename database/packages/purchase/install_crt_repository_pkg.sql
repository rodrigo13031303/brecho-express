WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF
PROMPT Installing CRT_REPOSITORY_PKG...
@@crt_repository_pkg.pks
SHOW ERRORS PACKAGE crt_repository_pkg
@@crt_repository_pkg.pkb
SHOW ERRORS PACKAGE BODY crt_repository_pkg
PROMPT CRT_REPOSITORY_PKG installed successfully.
