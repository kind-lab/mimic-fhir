DROP TABLE IF EXISTS fhir_etl.map_encounter_class;
CREATE TABLE fhir_etl.map_encounter_class(
    mimic_class VARCHAR,
    fhir_class_code VARCHAR,
    fhir_class_display VARCHAR
);


INSERT INTO fhir_etl.map_encounter_class
    (mimic_class, fhir_class_code, fhir_class_display)
VALUES 
    ('EU OBSERVATION', 'OBSENC', 'observation encounter'),
    ('URGENT', 'AMB', 'ambulatory'), -- ambulatory captures outpatient
    ('ELECTIVE', 'AMB', 'ambulatory'), -- ambulatory captures outpatient
    ('AMBULATORY OBSERVATION', 'AMB', 'ambulatory'),
    ('SURGICAL SAME DAY ADMISSION', 'SS', 'short stay'),
    ('DIRECT OBSERVATION', 'OBSENC', 'observation encounter'),
    ('DIRECT EMER.', 'EMER', 'emergency'),
    ('OBSERVATION ADMIT', 'OBSENC', 'observation encounter'),
    ('EW EMER.', 'EMER', 'emergency')
