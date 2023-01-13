-- Medication Site Codesystem
-- Need to map out to SNOMED route codes - http://hl7.org/fhir/valueset-route-codes.html

DROP TABLE IF EXISTS fhir_trm.cs_medication_site;
CREATE TABLE fhir_trm.cs_medication_site(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_medication_site
SELECT DISTINCT TRIM(REGEXP_REPLACE(site, '\s+', ' ', 'g')) -- need TO remove ALL whitespaces TO pass fhir validation
FROM mimiciv_hosp.emar_detail
WHERE 
    site IS NOT NULL 
    AND TRIM(REGEXP_REPLACE(site, '\s+', ' ', 'g')) != ''