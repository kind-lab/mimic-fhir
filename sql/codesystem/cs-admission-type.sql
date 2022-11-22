-- Admission type CodeSystem
-- Codes will need to be mapped to match US Core Encounter Type -http://hl7.org/fhir/ValueSet/encounter-type

DROP TABLE IF EXISTS fhir_trm.cs_admission_type;
CREATE TABLE fhir_trm.cs_admission_type(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_admission_type
SELECT DISTINCT admission_type 
FROM mimiciv_hosp.admissions 
WHERE admission_type != ''
