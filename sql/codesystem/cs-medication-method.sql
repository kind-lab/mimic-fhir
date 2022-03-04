SELECT DISTINCT TRIM(event_txt) AS methods FROM mimic_hosp.emar  
UNION
SELECT DISTINCT TRIM(ordercategorydescription) AS methods FROM mimic_icu.inputevents i 
