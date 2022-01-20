DROP TABLE IF EXISTS fhir_etl.map_gender;
CREATE TABLE fhir_etl.map_gender(
  	mimic_gender VARCHAR NOT NULL,
    fhir_gender VARCHAR NOT NULL
);


INSERT INTO fhir_etl.map_gender
	(mimic_gender, fhir_gender)
VALUES 
	('F', 'female'),
	('M', 'male')

