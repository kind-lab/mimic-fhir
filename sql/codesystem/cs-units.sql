-- Generate the unique set of units across all tables in MIMIC
-- Potentially map to the fhir units codesystem - http://unitsofmeasure.org

DROP TABLE IF EXISTS fhir_trm.cs_units;
CREATE TABLE fhir_trm.cs_units(
    code      VARCHAR NOT NULL
);


WITH mimic_units AS (
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
    
    -- Prescription units 
    SELECT DISTINCT TRIM(dose_unit_rx) AS unit FROM mimic_hosp.prescriptions p   
)
INSERT INTO fhir_trm.cs_units
SELECT unit
FROM mimic_units
WHERE 
    unit IS NOT NULL 
    AND unit != ''




