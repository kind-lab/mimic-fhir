-- Careunit class CodeSystem

DROP TABLE IF EXISTS fhir_trm.cs_careunit;
CREATE TABLE fhir_trm.cs_careunit(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_careunit 
SELECT DISTINCT careunit 
FROM mimic_core.transfers
WHERE careunit IS NOT NULL;
