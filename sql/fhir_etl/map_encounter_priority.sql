DROP TABLE IF EXISTS fhir_etl.map_encounter_priority;
CREATE TABLE fhir_etl.map_encounter_priority(
    mimic_priority VARCHAR,
    fhir_priority_code VARCHAR,
    fhir_priority_display VARCHAR
);


INSERT INTO fhir_etl.map_encounter_priority
    (mimic_priority, fhir_priority_code, fhir_priority_display)
VALUES 
    ('EU OBSERVATION', 'R', 'routine'),
    ('URGENT', 'UR', 'urgent'), -- ambulatory captures outpatient
    ('ELECTIVE', 'EL', 'elective'), -- ambulatory captures outpatient
    ('AMBULATORY OBSERVATION', 'R', 'routine'),
    ('SURGICAL SAME DAY ADMISSION', 'R', 'routine'),
    ('DIRECT OBSERVATION', 'R', 'routine'),
    ('DIRECT EMER.', 'EM', 'emergency'),
    ('OBSERVATION ADMIT', 'R', 'routine'),
    ('EW EMER.', 'EM', 'emergency')
