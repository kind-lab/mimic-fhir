SELECT DISTINCT TRIM(route) FROM mimic_hosp.emar_detail 
UNION
SELECT DISTINCT TRIM(route) FROM mimic_hosp.pharmacy