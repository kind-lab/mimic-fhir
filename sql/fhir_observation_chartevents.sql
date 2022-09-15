-- Purpose: Generate a FHIR Observation resource for each chartevents row
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit

DROP TABLE IF EXISTS mimic_fhir.observation_chartevents;
CREATE TABLE mimic_fhir.observation_chartevents(
    id          uuid PRIMARY KEY,
    patient_id  uuid NOT NULL,
    fhir        jsonb NOT NULL
);

WITH fhir_observation_ce as (
    SELECT
        CAST(ce.itemid AS TEXT) AS ce_ITEMID
        , CAST(ce.charttime AS TIMESTAMPTZ) AS ce_CHARTTIME
        , CAST(ce.storetime AS TIMESTAMPTZ) AS ce_STORETIME
        , ce.valueuom AS ce_VALUEUOM
        , ce.valuenum AS ce_VALUENUM
        , ce.value AS ce_VALUE
        , di.label AS di_LABEL
        , di.category AS di_CATEGORY
        , di.lownormalvalue AS di_LOWNORMALVALUE
        , di.highnormalvalue AS di_HIGHNORMALVALUE

        -- reference uuids
        -- chartevents uuid dependent on 'value' to be unique (stay_id and itemid should be enough but a couple cases break this)
        , uuid_generate_v5(ns_observation_ce.uuid, ce.stay_id || '-' || ce.charttime || '-' || ce.itemid || '-' ||ce.value) AS uuid_CHARTEVENTS
        , uuid_generate_v5(ns_patient.uuid, CAST(ce.subject_id AS text)) AS uuid_SUBJECT_ID
        , uuid_generate_v5(ns_encounter_icu.uuid, CAST(ce.stay_id AS text)) AS uuid_STAY_ID
    FROM
        mimic_icu.chartevents ce
        LEFT JOIN mimic_icu.d_items di
            ON ce.itemid = di.itemid
        LEFT JOIN fhir_etl.uuid_namespace ns_encounter_icu
            ON ns_encounter_icu.name = 'EncounterICU'
        LEFT JOIN fhir_etl.uuid_namespace ns_patient
            ON ns_patient.name = 'Patient'
        LEFT JOIN fhir_etl.uuid_namespace ns_observation_ce
            ON ns_observation_ce.name = 'ObservationChartevents'
    WHERE   
        -- filter out the one duplicate value (one patient at one charttime)
        ((stay_id = 34934165) AND (charttime = '2151-10-03 05:14:00.000')) = FALSE
        AND value IS NOT NULL -- one value in the whole TABLE
)
INSERT INTO mimic_fhir.observation_chartevents
SELECT 
    uuid_CHARTEVENTS AS id
    , uuid_SUBJECT_ID AS patient_id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Observation'
        , 'id', uuid_CHARTEVENTS
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://mimic.mit.edu/fhir/StructureDefinition/mimic-observation-chartevents'
            )
        )
        , 'status', 'final' -- All observations considered final
        , 'category', jsonb_build_array(jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://mimic.mit.edu/fhir/CodeSystem/mimic-observation-category'
                , 'code', di_CATEGORY
            ))
        ))
        , 'code', jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://mimic.mit.edu/fhir/CodeSystem/mimic-chartevents-d-items'
                , 'code', ce_ITEMID
                , 'display', di_LABEL
            ))
        )
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'encounter', jsonb_build_object('reference', 'Encounter/' || uuid_STAY_ID) 
        , 'effectiveDateTime', ce_CHARTTIME
        , 'issued', ce_STORETIME -- issued element is the instant the observation was available
        , 'valueQuantity',
            CASE WHEN ce_VALUENUM IS NOT NULL THEN
                jsonb_build_object(
                    'value', ce_VALUENUM
                    , 'unit', ce_VALUEUOM
                    , 'system', 'http://mimic.mit.edu/fhir/CodeSystem/mimic-units'
                    , 'code', ce_VALUEUOM 
            ) ELSE NULL END
        , 'valueString',
            CASE WHEN ce_VALUENUM IS NULL THEN
                ce_VALUE
            ELSE NULL END
        , 'referenceRange',
            CASE WHEN di_LOWNORMALVALUE IS NOT NULL OR di_HIGHNORMALVALUE IS NOT NULL THEN
                jsonb_build_array(jsonb_build_object(
                    'low',
                        CASE WHEN di_LOWNORMALVALUE IS NOT NULL THEN
                            jsonb_build_object(
                                'value', di_LOWNORMALVALUE
                                , 'unit', ce_VALUEUOM
                                , 'system', 'http://mimic.mit.edu/fhir/CodeSystem/mimic-units'
                                , 'code', ce_VALUEUOM
                            )
                        ELSE NULL END
                    , 'high',
                        CASE WHEN di_HIGHNORMALVALUE IS NOT NULL THEN
                            jsonb_build_object(
                                'value', di_HIGHNORMALVALUE
                                , 'unit', ce_VALUEUOM
                                , 'system', 'http://mimic.mit.edu/fhir/CodeSystem/mimic-units'
                                , 'code', ce_VALUEUOM
                            )
                        ELSE NULL END
        )) ELSE NULL END
    )) AS fhir
FROM
    fhir_observation_ce;
