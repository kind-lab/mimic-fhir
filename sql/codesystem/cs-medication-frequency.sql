-- Generate codes for medication-frequnecy CodeSystem
SELECT DISTINCT TRIM(REGEXP_REPLACE(frequency, '\s+', ' ', 'g')) AS drug FROM mimic_hosp.pharmacy p 