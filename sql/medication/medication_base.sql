DROP TABLE IF EXISTS mimic_fhir.medication;
CREATE TABLE mimic_fhir.medication(
    id      uuid PRIMARY KEY,
    fhir    jsonb NOT NULL 
);
