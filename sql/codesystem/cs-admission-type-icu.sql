-- Admission type icu CodeSystem
-- Codes will need to be mapped to match US Core EncounterType - http://hl7.org/fhir/us/core/ValueSet-us-core-encounter-type.html
-- Source from mimic_core.transfers table, since it holds all careunits that could be used in ICU


DROP TABLE IF EXISTS fhir_trm.cs_admission_type_icu;
CREATE TABLE fhir_trm.cs_admission_type_icu(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_admission_type_icu
SELECT DISTINCT careunit 
FROM mimic_core.transfers
WHERE careunit IS NOT NULL
