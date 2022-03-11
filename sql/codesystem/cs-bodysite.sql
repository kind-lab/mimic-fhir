-- Bodysite Codesystem
-- Need to map out to SNOMED codes - http://hl7.org/fhir/R4/valueset-body-site.html

DROP TABLE IF EXISTS fhir_trm.bodysite;
CREATE TABLE fhir_trm.bodysite(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.bodysite
SELECT DISTINCT location 
FROM mimic_icu.procedureevents p 
WHERE location IS NOT NULL