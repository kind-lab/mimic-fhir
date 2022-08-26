DROP TABLE IF EXISTS fhir_etl.map_micro_interpretation;
CREATE TABLE fhir_etl.map_micro_interpretation(
    mimic_interpretation VARCHAR,
    fhir_interpretation_code VARCHAR,
    fhir_interpretation_display VARCHAR
);


INSERT INTO fhir_etl.map_micro_interpretation
    (mimic_interpretation, fhir_interpretation_code, fhir_interpretation_display)
VALUES 
    ('I', 'IND', 'Indeterminate'),
    ('P', 'IE', 'Insufficient evidence'), -- ONLY 4 VALUES IN ALL OF microbiologevents
    ('R', 'R', 'Resistant'),
    ('S', 'S', 'Susceptible')
