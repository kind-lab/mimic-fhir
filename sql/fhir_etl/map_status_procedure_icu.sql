DROP TABLE IF EXISTS fhir_etl.map_status_procedure_icu;
CREATE TABLE fhir_etl.map_status_procedure_icu(
  	mimic_status VARCHAR,
    fhir_status VARCHAR
);


INSERT INTO fhir_etl.map_status_procedure_icu
	(mimic_status, fhir_status)
VALUES 
	('FinishedRunning', 'completed'),
	('Paused', 'on-hold'),
	('Stopped', 'stopped')

	

