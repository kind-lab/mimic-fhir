DROP TABLE IF EXISTS fhir_etl.map_drug_id;
CREATE TABLE fhir_etl.map_drug_id(
  	drug_id INT GENERATED ALWAYS AS IDENTITY,
    drug VARCHAR NOT NULL
);



INSERT INTO fhir_etl.map_drug_id(drug)
SELECT DISTINCT drug 
FROM mimic_hosp.prescriptions
WHERE ndc = '0' or ndc IS NULL OR ndc = '';
