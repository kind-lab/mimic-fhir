-- Generate codes for procedure-icd9 codesystem
-- Only taking the codes used in procedure_icd versus all the codes in d_icd_procedures 
-- Need to trim to remove whitespaces, or validator will fail it

DROP TABLE IF EXISTS fhir_trm.cs_procedure_icd9;
CREATE TABLE fhir_trm.cs_procedure_icd9(
    code      VARCHAR NOT NULL,
    display   VARCHAR
);

INSERT INTO fhir_trm.cs_procedure_icd9
SELECT DISTINCT 
    TRIM(proc.icd_code) AS code
    , icd.long_title AS display
FROM 
    mimiciv_hosp.procedures_icd proc
    LEFT JOIN mimiciv_hosp.d_icd_procedures icd
        ON proc.icd_code = icd.icd_code 
        AND proc.icd_version = icd.icd_version 
WHERE proc.icd_version = 9

