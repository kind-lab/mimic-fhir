-- Generate codes for procedure-icd10 codesystem
-- Only taking the codes used in procedure_icd versus all the codes in d_icd_procedures 
-- Need to trim to remove whitespaces, or validator will fail it

SELECT DISTINCT TRIM(proc.icd_code) AS icd_code, icd.long_title 
FROM 
    mimic_hosp.procedures_icd proc
    LEFT JOIN mimic_hosp.d_icd_procedures icd
        ON proc.icd_code = icd.icd_code 
        AND proc.icd_version = icd.icd_version 
WHERE proc.icd_version = 10

