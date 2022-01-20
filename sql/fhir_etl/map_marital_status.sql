DROP TABLE IF EXISTS fhir_etl.map_marital_status;
CREATE TABLE fhir_etl.map_marital_status(
  	mimic_marital_status VARCHAR,
    fhir_marital_status VARCHAR,
    fhir_system VARCHAR
);


INSERT INTO fhir_etl.map_marital_status
	(mimic_marital_status, fhir_marital_status, fhir_system)
VALUES 
	('MARRIED', 'M', 'http://terminology.hl7.org/CodeSystem/v3-MaritalStatus'),
	('SINGLE', 'S', 'http://terminology.hl7.org/CodeSystem/v3-MaritalStatus'),
	('WIDOWED', 'W', 'http://terminology.hl7.org/CodeSystem/v3-MaritalStatus'),
	('DIVORCED', 'D', 'http://terminology.hl7.org/CodeSystem/v3-MaritalStatus'),
	(NULL, 'UNK', 'http://terminology.hl7.org/CodeSystem/v3-NullFlavor')
	

