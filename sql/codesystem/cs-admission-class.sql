-- Admission class CodeSystem
-- Codes will need to be mapped to match US Core Act Encounter Code - http://terminology.hl7.org/ValueSet/v3-ActEncounterCode

DROP TABLE IF EXISTS fhir_trm.cs_admission_class;
CREATE TABLE fhir_trm.cs_admission_class(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_admission_class 
SELECT DISTINCT admission_type 
FROM mimiciv_hosp.admissions 
