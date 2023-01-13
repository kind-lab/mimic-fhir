-- Medication method CodeSystem
-- Could map to SNOMED codes - http://hl7.org/fhir/valueset-administration-method-codes.html

DROP TABLE IF EXISTS fhir_trm.cs_medication_method;
CREATE TABLE fhir_trm.cs_medication_method(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_medication_method
SELECT DISTINCT TRIM(event_txt) 
FROM mimiciv_hosp.emar  
WHERE event_txt IS NOT NULL;

