-- Admit source CodeSystem
-- Codes will need to be mapped to match AdmitSource- http://hl7.org/fhir/R4/valueset-encounter-admit-source.html

DROP TABLE IF EXISTS fhir_trm.cs_admit_source;
CREATE TABLE fhir_trm.cs_admit_source(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_admit_source
SELECT DISTINCT admission_location  
FROM mimic_hosp.admissions a 
WHERE admission_location IS NOT NULL
