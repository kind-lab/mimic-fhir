-- Discharge disposition CodeSystem
-- Codes will need to be mapped to match DischargeDisposition- http://hl7.org/fhir/R4/valueset-encounter-discharge-disposition.html

DROP TABLE IF EXISTS fhir_trm.cs_discharge_disposition;
CREATE TABLE fhir_trm.cs_discharge_disposition(
    code      VARCHAR NOT NULL
);

WITH mimic_discharge_disposition AS (

    -- Hospital admission sources
    SELECT DISTINCT discharge_location AS code FROM mimic_hosp.admissions 
    UNION
    
    -- ED admission sources
    SELECT DISTINCT disposition AS code FROM mimic_ed.edstays 
)
INSERT INTO fhir_trm.cs_discharge_disposition
SELECT code
FROM mimic_discharge_disposition
WHERE 
    code IS NOT NULL 

