-- Purpose: Generate a FHIR Observation resource for each row in outputevents
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit

DROP TABLE IF EXISTS mimic_fhir.observation_outputevents;
CREATE TABLE mimic_fhir.observation_outputevents(
    id          uuid PRIMARY KEY,
    patient_id  uuid NOT NULL,
    fhir        jsonb NOT NULL
);

WITH fhir_observation_oe AS (
    SELECT
        CAST(oe.itemid AS TEXT) AS oe_ITEMID
        , CAST(oe.charttime AS TIMESTAMPTZ) AS oe_CHARTTIME
        , CAST(oe.storetime AS TIMESTAMPTZ) AS oe_STORETIME
        , oe.valueuom AS oe_VALUEUOM
        , oe.value AS oe_VALUE
        , di.label AS di_LABEL
        , di.category AS di_CATEGORY
  
        -- reference uuids
        , uuid_generate_v5(ns_observation_oe.uuid, oe.stay_id || '-' || oe.charttime || '-' || oe.itemid) as uuid_OUTPUTEVENT
        , uuid_generate_v5(ns_patient.uuid, CAST(oe.subject_id AS TEXT)) AS uuid_SUBJECT_ID
        , uuid_generate_v5(ns_encounter_icu.uuid, CAST(oe.stay_id AS TEXT)) AS uuid_STAY_ID
    FROM
        mimic_icu.outputevents oe
        LEFT JOIN mimic_icu.d_items di
            ON oe.itemid = di.itemid
        LEFT JOIN fhir_etl.uuid_namespace ns_encounter_icu
            ON ns_encounter_icu.name = 'EncounterICU'
        LEFT JOIN fhir_etl.uuid_namespace ns_patient
            ON ns_patient.name = 'Patient'
        LEFT JOIN fhir_etl.uuid_namespace ns_observation_oe
            ON ns_observation_oe.name = 'ObservationOutputevents'
)
INSERT INTO mimic_fhir.observation_outputevents
SELECT 
    uuid_OUTPUTEVENT AS id
    , uuid_SUBJECT_ID AS patient_id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Observation'
        , 'id', uuid_OUTPUTEVENT
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://mimic.mit.edu/fhir/StructureDefinition/mimic-observation-outputevents'
            )
        ) 
        , 'status', 'final'
        , 'category', jsonb_build_array(jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://mimic.mit.edu/fhir/CodeSystem/mimic-observation-category'  
                , 'code', di_CATEGORY
            ))
        ))
        -- Item code for outputevent
        , 'code', jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://mimic.mit.edu/fhir/CodeSystem/mimic-d-items'
                , 'code', oe_ITEMID
                , 'display', di_LABEL
            ))
        )
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'encounter', jsonb_build_object('reference', 'Encounter/' || uuid_STAY_ID)
        , 'effectiveDateTime', oe_CHARTTIME
        , 'issued', oe_STORETIME
        , 'valueQuantity',
            jsonb_build_object(
                'value', oe_VALUE
                , 'unit', oe_VALUEUOM
                , 'system', 'http://mimic.mit.edu/fhir/CodeSystem/mimic-units'
                , 'code', oe_VALUEUOM
            )
    )) AS fhir
FROM
    fhir_observation_oe;
