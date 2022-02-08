DROP TABLE IF EXISTS fhir_etl.map_med_duration_unit;
CREATE TABLE fhir_etl.map_med_duration_unit(
  	mimic_unit VARCHAR NOT NULL,
    fhir_unit VARCHAR
);


INSERT INTO fhir_etl.map_med_duration_unit
	(mimic_unit, fhir_unit)
VALUES 
	('Doses', NULL),
	('Hours', 'h'),
	('Months', 'mo'),
	('Weeks', 'wk'),
	('Days', 'd'),
	('Ongoing', NULL)

