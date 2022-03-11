-- Admission class CodeSystem
-- Codes will need to be mapped to match US Core Act Encounter Code - http://terminology.hl7.org/CodeSystem/v3-ActCode

DROP TABLE IF EXISTS fhir_trm.admission_class;
CREATE TABLE fhir_trm.admission_class(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.admission_class 
SELECT DISTINCT admission_type 
FROM mimic_core.admissions 
