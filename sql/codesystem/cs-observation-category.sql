-- Observation Category CodeSystem

DROP TABLE IF EXISTS fhir_trm.cs_observation_category;
CREATE TABLE fhir_trm.cs_observation_category(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_observation_category
SELECT DISTINCT di.category
FROM mimic_icu.d_items di 


