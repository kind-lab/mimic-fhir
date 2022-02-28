DROP TABLE IF EXISTS mimic_fhir.specimen;
CREATE TABLE mimic_fhir.specimen(
    id          uuid PRIMARY KEY,
    patient_id  uuid NOT NULL,
    fhir        jsonb NOT NULL 
);

WITH fhir_specimen AS (
    SELECT 
        mi.micro_specimen_id  AS mi_MICRO_SPECIMEN_ID
        , MAX(mi.subject_id) AS mi_SUBJECT_ID
        , CAST(MAX(mi.charttime) AS TIMESTAMPTZ) AS mi_charttime

        , uuid_generate_v5(ns_observation_micro_org.uuid, mi.micro_specimen_id) AS uuid_SPECIMEN
        , uuid_generate_v5(ns_patient.uuid, CAST(mi.subject_id AS TEXT)) as uuid_SUBJECT_ID 
    FROM 
        mimic_hosp.microbiologyevents mi
        INNER JOIN fhir_etl.subjects sub
            ON mi.subject_id = sub.subject_id 
        LEFT JOIN fhir_etl.uuid_namespace ns_patient
            ON ns_patient.name = 'Patient'
        LEFT JOIN fhir_etl.uuid_namespace ns_observation_micro_org
            ON ns_observation_micro_org.name = 'Specimen'
    GROUP BY 
        micro_specimen_id 
)  
  
INSERT INTO mimic_fhir.specimen 
SELECT 
    uuid_SPECIMEN  AS id
    , uuid_SUBJECT_ID AS patient_id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Specimen'
        , 'id', uuid_MICRO_SUSC 
        , 'identifier',   jsonb_build_array(jsonb_build_object(
            'value', mi_MICRO_SPECIMEN_ID
            , 'system', 'http://fhir.mimic.mit.edu/identifier/specimen'
        ))      
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'collection', jsonb_build_object(
            'collectedDateTime', mi_CHARTTIME
        ) 
    )) AS fhir
FROM
    fhir_specimen
