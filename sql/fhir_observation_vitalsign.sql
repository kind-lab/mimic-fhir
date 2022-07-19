-- Purpose: Generate a FHIR Observation resource for each row in vitalsign
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit

--########################################
-- UNDER DEVELOPMENT, NOT FUNCTIONAL
-- #######################################

DROP TABLE IF EXISTS mimic_fhir.observation_vitalsign;
CREATE TABLE mimic_fhir.observation_vitalsign(
    id          uuid PRIMARY KEY,
    patient_id  uuid NOT NULL,
    fhir        jsonb NOT NULL
);

WITH fhir_observation_oe AS (
    SELECT
        vs.stay_id || '-' || vs.charttime AS vs_IDENTIFIER
        , CAST(vs.charttime AS TIMESTAMPTZ) AS vs_CHARTTIME
        , temperature AS vs_TEMPERATURE
        , heartrate AS vs_HEARTRATE
        , resprate AS vs_RESPRATE
        , dbp AS vs_DBP
        , sbp AS vs_SBP
        , o2sat AS vs_O2SAT
  
        -- reference uuids
        , uuid_generate_v5(ns_observation_vs.uuid, vs.stay_id || '-' || vs.charttime) as uuid_VITALSIGN
        , uuid_generate_v5(ns_patient.uuid, CAST(oe.subject_id AS TEXT)) AS uuid_SUBJECT_ID
        , uuid_generate_v5(ns_encounter_ed.uuid, CAST(vs.stay_id AS TEXT)) AS uuid_STAY_ID
    FROM
        mimic_ed.vitalsign vs
        LEFT JOIN fhir_etl.uuid_namespace ns_encounter_ed
            ON ns_encounter_ed.name = 'EncounterED'
        LEFT JOIN fhir_etl.uuid_namespace ns_patient
            ON ns_patient.name = 'Patient'
        LEFT JOIN fhir_etl.uuid_namespace ns_observation_vs
            ON ns_observation_vs.name = 'ObservationVitalSign'
)
INSERT INTO mimic_fhir.observation_outputevents
SELECT 
    uuid_VITALSIGN AS id
    , uuid_SUBJECT_ID AS patient_id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Observation'
        , 'id', uuid_VITALSIGN
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://fhir.mimic.mit.edu/StructureDefinition/mimic-observation-vitalsign'
            )
        ) 
        , 'identifier',  jsonb_build_array(jsonb_build_object(
            'value', vs_IDENTIFIER
            , 'system', 'http://fhir.mimic.mit.edu/identifier/observation-vitalsign'
        ))
        , 'status', 'final'
        , 'category', jsonb_build_array(jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://fhir.mimic.mit.edu/CodeSystem/mimic-observation-category'  
                , 'code', di_CATEGORY
            ))
        ))
        -- Item code for outputevent
        , 'code', jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://fhir.mimic.mit.edu/CodeSystem/mimic-d-items'
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
                , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/mimic-units'
                , 'code', oe_VALUEUOM
            )
    )) AS fhir
FROM
    fhir_observation_oe;
