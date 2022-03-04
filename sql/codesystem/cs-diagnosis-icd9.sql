-- Generate codes for diagnosis-icd9 codesystem
-- Only taking the codes used in diagnosis_icd versus all the codes in d_icd_diagnosis
-- Need to trim to remove whitespaces, or validator will fail it

SELECT 
    DISTINCT TRIM(diag.icd_code) AS icd_code, icd.long_title 
FROM 
    mimic_hosp.diagnoses_icd diag
    LEFT JOIN mimic_hosp.d_icd_diagnoses icd
        ON diag.icd_code = icd.icd_code 
        AND diag.icd_version = icd.icd_version 
WHERE diag.icd_version = 9

