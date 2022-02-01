-- Medication Administration units
SELECT DISTINCT TRIM(REGEXP_REPLACE(dose_due_unit, '\s+', ' ', 'g')) AS unit FROM mimic_hosp.emar_detail
UNION
SELECT DISTINCT TRIM(infusion_rate_unit) AS unit FROM mimic_hosp.emar_detail
UNION 

-- Medication Administration ICU units
SELECT DISTINCT TRIM(amountuom)  AS unit FROM mimic_icu.inputevents 
UNION
SELECT DISTINCT TRIM(rateuom) AS unit FROM mimic_icu.inputevents 
UNION 

-- Chartevents units 
SELECT DISTINCT TRIM(valueuom) AS unit FROM mimic_icu.chartevents  
UNION

-- Observation labs units
SELECT DISTINCT TRIM(valueuom) AS unit FROM mimic_hosp.labevents   
UNION

-- Outputevents units 
SELECT DISTINCT TRIM(valueuom) AS unit FROM mimic_icu.outputevents  