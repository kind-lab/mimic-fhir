-- Medication Frequency CodeSystem

DROP TABLE IF EXISTS fhir_trm.cs_medication_frequency;
CREATE TABLE fhir_trm.cs_medication_frequency(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_medication_frequency
SELECT DISTINCT TRIM(REGEXP_REPLACE(frequency, '\s+', ' ', 'g')) AS code 
FROM mimic_hosp.pharmacy p 
WHERE frequency IS NOT NULL;
 