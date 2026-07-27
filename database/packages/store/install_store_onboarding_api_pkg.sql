SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

@@store_onboarding_api_pkg.pks
SHOW ERRORS PACKAGE store_onboarding_api_pkg

@@store_onboarding_api_pkg.pkb
SHOW ERRORS PACKAGE BODY store_onboarding_api_pkg

DECLARE
  l_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO l_count
    FROM USER_OBJECTS
   WHERE OBJECT_NAME = 'STORE_ONBOARDING_API_PKG'
     AND OBJECT_TYPE IN ('PACKAGE', 'PACKAGE BODY')
     AND STATUS = 'VALID';
  IF l_count <> 2 THEN
    RAISE_APPLICATION_ERROR(-20999, 'STORE_ONBOARDING_API_PKG was not installed correctly.');
  END IF;
END;
/