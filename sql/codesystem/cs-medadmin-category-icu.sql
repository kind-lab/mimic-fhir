-- Medadmin Category ICU Codesystem
-- May need to map out to medadmin category - http://hl7.org/fhir/valueset-medication-admin-category.html

DROP TABLE IF EXISTS fhir_trm.medadmin_category_icu;
CREATE TABLE fhir_trm.medadmin_category_icu(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.medadmin_category_icu
SELECT DISTINCT ordercategoryname 
FROM mimic_icu.inputevents 