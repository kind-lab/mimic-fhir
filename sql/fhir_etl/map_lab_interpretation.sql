DROP TABLE IF EXISTS fhir_etl.map_lab_interpretation;
CREATE TABLE fhir_etl.map_lab_interpretation(
    mimic_interpretation VARCHAR,
    fhir_interpretation_code VARCHAR,
    fhir_interpretation_display VARCHAR
);


INSERT INTO fhir_etl.map_lab_interpretation
    (mimic_interpretation, fhir_interpretation_code, fhir_interpretation_display)
VALUES 
    ('A', 'A', 'abnormal')

