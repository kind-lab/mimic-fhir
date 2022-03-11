-- Observation Category CodeSystem

DROP TABLE IF EXISTS fhir_trm.observation_category;
CREATE TABLE fhir_trm.observation_category(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.observation_category
SELECT DISTINCT di.category
FROM mimic_icu.d_items di 


