-- Generate codes for diagnosis-icd10 codesystem
-- Take codes used in mimic_hosp.diagnosis_icd and mimic_ed.diagnosis
-- Combine all the codes from MIMIC-IV and MIMIC-ED to make sure all ICD codes captured
-- Need to trim to remove whitespaces, or validator will fail it
-- FUTURE: fhir should have all these codes in the terminology server, but only have fragmented version.
--         So can swap to the fhir version when it is complete


DROP TABLE IF EXISTS fhir_trm.cs_diagnosis_icd10;
CREATE TABLE fhir_trm.cs_diagnosis_icd10(
    code      VARCHAR NOT NULL,
    display   VARCHAR NOT NULL
);


WITH icd10_codes AS (
    SELECT 
        DISTINCT TRIM(diag.icd_code) AS code
        , icd.long_title AS display
    FROM 
        mimic_hosp.diagnoses_icd diag
        LEFT JOIN mimic_hosp.d_icd_diagnoses icd
            ON diag.icd_code = icd.icd_code 
            AND diag.icd_version = icd.icd_version 
    WHERE diag.icd_version = 10
    
    UNION 
    
    SELECT 
        DISTINCT TRIM(eddg.icd_code) AS code
        , eddg.icd_title AS display
    FROM
        mimic_ed.diagnosis eddg
    WHERE icd_version = 10   
)
INSERT INTO fhir_trm.cs_diagnosis_icd10
SELECT 
    code
    , display
FROM icd10_codes



