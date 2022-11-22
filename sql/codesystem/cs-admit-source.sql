-- Admit source CodeSystem
-- Codes will need to be mapped to match AdmitSource- http://hl7.org/fhir/R4/valueset-encounter-admit-source.html

DROP TABLE IF EXISTS fhir_trm.cs_admit_source;
CREATE TABLE fhir_trm.cs_admit_source(
    code      VARCHAR NOT NULL
);

WITH mimic_admit_source AS (

    -- Hospital admission sources
    SELECT DISTINCT admission_location AS code FROM mimiciv_hosp.admissions 
    UNION
    
    -- ED admission sources
    SELECT DISTINCT arrival_transport AS code FROM mimic_ed.edstays 
)
INSERT INTO fhir_trm.cs_admit_source
SELECT code
FROM mimic_admit_source
WHERE 
    code IS NOT NULL 

