-- Medication ICU CodeSystem
-- Medication used in the ICU, will need to be concept mapped to a standard meds codesystem later

DROP TABLE IF EXISTS fhir_trm.cs_medication_icu;
CREATE TABLE fhir_trm.cs_medication_icu(
    code      VARCHAR NOT NULL,
    display   VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_medication_icu
SELECT 
    itemid AS code
    , LABEL AS display
FROM mimic_icu.d_items 

