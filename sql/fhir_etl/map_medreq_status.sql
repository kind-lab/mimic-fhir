DROP TABLE IF EXISTS fhir_etl.map_medreq_status;
CREATE TABLE fhir_etl.map_medreq_status(
  	mimic_status VARCHAR,
    fhir_status VARCHAR
);


INSERT INTO fhir_etl.map_medreq_status
	(mimic_status, fhir_status)
VALUES 
	('Discontinued via patient discharge', 'completed'),
	('Inactive (Due to a change order)', 'stopped'),
	('TPN Order (Acknowledged, Not Pumped)', 'draft'),
	('U', 'unknown'),
	('Expired', 'stopped'),
	('Active', 'active'),
	('Discontinued', 'completed'),
	('H', 'unknown')
	

	

