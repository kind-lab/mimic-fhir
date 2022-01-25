DROP TABLE IF EXISTS fhir_etl.subjects;
CREATE TABLE fhir_etl.subjects(
  	subject_id INT NOT NULL
);


INSERT INTO fhir_etl.subjects(subject_id)
SELECT subject_id
FROM mimic_core.patients
WHERE subject_id < 10010000;
