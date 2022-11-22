-- Lab flags CodeSystem
-- Needs to be mapped to Observation Interpretation system - https://build.fhir.org/valueset-observation-interpretation.html

DROP TABLE IF EXISTS fhir_trm.cs_lab_flags;
CREATE TABLE fhir_trm.cs_lab_flags(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_lab_flags
SELECT DISTINCT flag AS code
FROM mimiciv_hosp.labevents  
WHERE flag IS NOT NULL 
