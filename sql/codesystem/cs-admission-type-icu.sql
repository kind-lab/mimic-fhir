-- Admission type icu CodeSystem
-- Codes will need to be mapped to match US Core EncounterType - http://hl7.org/fhir/us/core/ValueSet-us-core-encounter-type.html


DROP TABLE IF EXISTS fhir_trm.admission_type_icu;
CREATE TABLE fhir_trm.admission_type_icu(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.admission_type_icu
SELECT DISTINCT first_careunit 
FROM mimic_icu.icustays
