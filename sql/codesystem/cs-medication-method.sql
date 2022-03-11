-- Medication method CodeSystem
-- Could map to SNOMED codes - http://hl7.org/fhir/valueset-administration-method-codes.html

DROP TABLE IF EXISTS fhir_trm.medication_method;
CREATE TABLE fhir_trm.medication_method(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.medication_method
SELECT DISTINCT TRIM(event_txt) 
FROM mimic_hosp.emar  
WHERE event_txt IS NOT NULL;


INSERT INTO fhir_trm.medication_method
SELECT DISTINCT TRIM(ordercategorydescription)
FROM mimic_icu.inputevents; 
