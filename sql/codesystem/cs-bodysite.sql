-- Bodysite Codesystem
-- Need to map out to SNOMED codes - http://hl7.org/fhir/R4/valueset-body-site.html

DROP TABLE IF EXISTS fhir_trm.cs_bodysite;
CREATE TABLE fhir_trm.cs_bodysite(
    code      VARCHAR NOT NULL
);


-- Need to trim and remove white spaces for codes to pass fhir validation
INSERT INTO fhir_trm.cs_bodysite
SELECT DISTINCT TRIM(REGEXP_REPLACE(location, '\s+', ' ', 'g'))
FROM mimiciv_icu.procedureevents p 
WHERE location IS NOT NULL