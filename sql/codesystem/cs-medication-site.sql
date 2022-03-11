-- Medication Site Codesystem
-- Need to map out to SNOMED route codes - http://hl7.org/fhir/valueset-route-codes.html

DROP TABLE IF EXISTS fhir_trm.medication_site;
CREATE TABLE fhir_trm.medication_site(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.medication_site
SELECT DISTINCT route 
FROM mimic_hosp.emar_detail
WHERE route IS NOT NULL