-- Purpose: Generate a FHIR Observation resource for each row in vitalsign
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit

DROP TABLE IF EXISTS mimic_fhir.observation_vitalsigns;
CREATE TABLE mimic_fhir.observation_vitalsigns(
    id          uuid PRIMARY KEY,
    patient_id  uuid NOT NULL,
    fhir        jsonb NOT NULL
);

--unnest vitalsigns, since each stored as individual fhir resource
WITH vitalsigns AS (
    SELECT 
        vs.subject_id
        , vs.stay_id
        , vs.charttime
        , x.*
        , vs.sbp
    FROM mimic_ed.vitalsign vs, jsonb_each_text(to_jsonb(vs)) AS x("key", value)
    WHERE KEY IN ('dbp', 'o2sat', 'rhythm', 'resprate', 'heartrate', 'temperature' ) -- pain excluded FOR now
), fhir_observation_vs AS (
    SELECT
        CAST(vs.charttime AS TIMESTAMPTZ) AS vs_CHARTTIME
        , vs.KEY AS vs_KEY
        , vs.value AS vs_VALUE
        , vs.sbp AS vs_SBP
  
        -- reference uuids
        , uuid_generate_v5(ns_observation_vs.uuid, vs.stay_id || '-' || vs.charttime || '-' || vs.key) as uuid_VITALSIGN
        , uuid_generate_v5(ns_patient.uuid, CAST(vs.subject_id AS TEXT)) AS uuid_SUBJECT_ID
        , uuid_generate_v5(ns_encounter_ed.uuid, CAST(vs.stay_id AS TEXT)) AS uuid_STAY_ID
        , uuid_generate_v5(ns_procedure.uuid, vs.stay_id || '-' || vs.charttime) AS uuid_PROCEDURE
    FROM
        vitalsigns vs
        LEFT JOIN fhir_etl.uuid_namespace ns_encounter_ed
            ON ns_encounter_ed.name = 'EncounterED'
        LEFT JOIN fhir_etl.uuid_namespace ns_patient
            ON ns_patient.name = 'Patient'
        LEFT JOIN fhir_etl.uuid_namespace ns_observation_vs
            ON ns_observation_vs.name = 'ObservationVitalSigns'
        LEFT JOIN fhir_etl.uuid_namespace ns_procedure
            ON ns_procedure.name = 'ProcedureED'
)
INSERT INTO mimic_fhir.observation_vitalsigns
SELECT 
    uuid_VITALSIGN AS id
    , uuid_SUBJECT_ID AS patient_id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Observation'
        , 'id', uuid_VITALSIGN
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://fhir.mimic.mit.edu/StructureDefinition/mimic-observation-vital-signs'
            )
        ) 
        , 'status', 'final'
        , 'category', jsonb_build_array(jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://terminology.hl7.org/CodeSystem/observation-category'  
                , 'code', 'vital-signs'
                , 'display', 'Vital Signs'
            ))
        ))
        -- Item code for outputevent
        , 'code', jsonb_build_object(
            'coding', jsonb_build_array(
                CASE 
                    WHEN vs_KEY = 'temperature' THEN
                        jsonb_build_object(
                            'system', 'http://loinc.org'
                            , 'code', '8310-5'
                            , 'display', 'Body temperature'
                        )   
                    WHEN vs_KEY = 'resprate' THEN
                        jsonb_build_object(
                            'system', 'http://loinc.org'
                            , 'code', '9279-1'
                            , 'display', 'Respiratory rate'
                        ) 
                    WHEN vs_KEY = 'heartrate' THEN
                        jsonb_build_object(
                            'system', 'http://loinc.org'
                            , 'code', '8867-4'
                            , 'display', 'Heart rate'
                        ) 
                    WHEN vs_KEY = 'o2sat' THEN
                        jsonb_build_object(
                            'system', 'http://loinc.org'
                            , 'code', '2708-6'
                            , 'display', 'Oxgyen saturation in Arterial blood'
                        )
                    WHEN vs_KEY = 'dbp' THEN
                        jsonb_build_object(
                            'system', 'http://loinc.org'
                            , 'code', '85354-9'
                            , 'display', 'Blood pressure panel with all children optional'
                        ) 
                END
            )
        )
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'encounter', jsonb_build_object('reference', 'Encounter/' || uuid_STAY_ID)
        , 'partOf', jsonb_build_object('reference', 'Procedure/' || uuid_PROCEDURE)
        , 'effectiveDateTime', vs_CHARTTIME
        , 'valueQuantity',
            CASE 
                WHEN vs_KEY = 'temperature' THEN
                    jsonb_build_object(
                        'value', vs_VALUE
                        , 'unit', 'F'
                        , 'system', 'http://unitsofmeasure.org'
                        , 'code', 'degF'
                    )
                WHEN vs_KEY = 'resprate' THEN
                    jsonb_build_object(
                        'value', vs_VALUE
                        , 'unit', 'breaths/minute'
                        , 'system', 'http://unitsofmeasure.org'
                        , 'code', '/min'
                    )
                WHEN vs_KEY = 'heartrate' THEN
                    jsonb_build_object(
                        'value', vs_VALUE
                        , 'unit', 'beats/minute'
                        , 'system', 'http://unitsofmeasure.org'
                        , 'code', '/min'
                    )
                WHEN vs_KEY = 'o2sat' THEN
                    jsonb_build_object(
                        'value', vs_VALUE
                        , 'unit', '%'
                        , 'system', 'http://unitsofmeasure.org'
                        , 'code', '%'
                    )
                ELSE NULL -- blood pressure stored in components
            END
        , 'component', CASE WHEN vs_KEY = 'dbp' THEN
            jsonb_build_array(
                jsonb_build_object(
                    'code', jsonb_build_object(
                        'system', 'http://loinc.org'
                        , 'code', '8480-6'
                        , 'display', 'Systolic blood pressure'
                    ) 
                    , 'valueQuantity', jsonb_build_object(
                        'value', vs_SBP
                        , 'unit', 'mm[Hg]'
                        , 'system', 'http://unitsofmeasure.org'
                        , 'code', 'mm[Hg]'
                    )
                ),
                jsonb_build_object(
                    'code', jsonb_build_object(
                        'system', 'http://loinc.org'
                        , 'code', ' 8462-4'
                        , 'display', 'Diastolic blood pressure'
                    ) 
                    , 'valueQuantity', jsonb_build_object(
                        'value', vs_VALUE
                        , 'unit', 'mm[Hg]'
                        , 'system', 'http://unitsofmeasure.org'
                        , 'code', 'mm[Hg]'
                    )
                )            
            )
        ELSE NULL END
    )) AS fhir
FROM
    fhir_observation_vs
LIMIT 1000;