-- Generate codes for diagnosis-icd9 codesystem
-- Only taking the codes used in diagnosis_icd versus all the codes in d_icd_diagnosis
-- Need to trim to remove whitespaces, or validator will fail it
-- FUTURE: fhir should have all these codes in the terminology server, but only have fragmented version.
--         So can swap to the fhir version when it is complete


DROP TABLE IF EXISTS fhir_trm.cs_diagnosis_icd9;
CREATE TABLE fhir_trm.cs_diagnosis_icd9(
    code      VARCHAR NOT NULL,
    display   VARCHAR NOT NULL
);


WITH icd9_codes AS (
    SELECT 
        DISTINCT TRIM(diag.icd_code) AS code
        , icd.long_title AS display
    FROM 
        mimiciv_hosp.diagnoses_icd diag
        LEFT JOIN mimiciv_hosp.d_icd_diagnoses icd
            ON diag.icd_code = icd.icd_code 
            AND diag.icd_version = icd.icd_version 
    WHERE diag.icd_version = 9
    
    UNION 
    
    SELECT 
        DISTINCT TRIM(eddg.icd_code) AS code
        , eddg.icd_title AS display
    FROM
        mimic_ed.diagnosis eddg
    WHERE icd_version = 9   
)
INSERT INTO fhir_trm.cs_diagnosis_icd9
SELECT 
    code
    , MAX(display) -- sometimes display IS slightly different (caps or lowercase)
FROM icd9_codes
GROUP BY code

