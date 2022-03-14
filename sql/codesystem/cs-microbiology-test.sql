-- Microbiology Test Codesystem

DROP TABLE IF EXISTS fhir_trm.cs_microbiology_test;
CREATE TABLE fhir_trm.cs_microbiology_test(
    code      VARCHAR NOT NULL,
    display   VARCHAR
);

INSERT INTO fhir_trm.cs_microbiology_test
SELECT DISTINCT 
    test_itemid AS code
    , test_name AS display 
FROM mimic_hosp.microbiologyevents m 
WHERE test_itemid IS NOT NULL