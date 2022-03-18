-- Medication Method ICU CodeSystem
-- Could map to SNOMED codes - http://hl7.org/fhir/valueset-administration-method-codes.html

DROP TABLE IF EXISTS fhir_trm.cs_medication_method_icu;
CREATE TABLE fhir_trm.cs_medication_method_icu(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_medication_method_icu
SELECT DISTINCT TRIM(ordercategorydescription)
FROM mimic_icu.inputevents; 
