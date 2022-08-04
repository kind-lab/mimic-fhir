-- Purpose: Generate a FHIR Observation resource for each row in triage
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit

DROP TABLE IF EXISTS mimic_fhir.observation_ed;
CREATE TABLE mimic_fhir.observation_ed(
    id          uuid PRIMARY KEY,
    patient_id  uuid NOT NULL,
    fhir        jsonb NOT NULL
);

-- Extra observations coming from vitalsigns (rhythm and pain)
WITH observation_ed AS (
    SELECT 
        vs.subject_id
        , vs.stay_id
        , vs.charttime
        , x.*
    FROM mimic_ed.vitalsign vs, jsonb_each_text(to_jsonb(vs)) AS x("key", value)
    WHERE KEY IN ('rhythm', 'pain' ) 
), fhir_observation_ed AS (
    SELECT
        ed.KEY AS ed_KEY
        , ed.value AS ed_VALUE
        , CAST(ed.charttime AS TIMESTAMPTZ) AS ed_CHARTTIME
        
        -- reference uuids
        , uuid_generate_v5(ns_observation_ed.uuid, ed.stay_id || '-' || ed.charttime || '-' || ed.key) as uuid_OBSERVATION_ED
        , uuid_generate_v5(ns_patient.uuid, CAST(ed.subject_id AS TEXT)) AS uuid_SUBJECT_ID
        , uuid_generate_v5(ns_encounter_ed.uuid, CAST(ed.stay_id AS TEXT)) AS uuid_STAY_ID
        , uuid_generate_v5(ns_procedure.uuid, ed.stay_id || '-' || ed.charttime) AS uuid_PROCEDURE
    FROM
        observation_ed ed
        INNER JOIN mimic_hosp.patients pat
            ON ed.subject_id = pat.subject_id
        LEFT JOIN fhir_etl.uuid_namespace ns_encounter_ed
            ON ns_encounter_ed.name = 'EncounterED'
        LEFT JOIN fhir_etl.uuid_namespace ns_patient
            ON ns_patient.name = 'Patient'
        LEFT JOIN fhir_etl.uuid_namespace ns_observation_ed
            ON ns_observation_ed.name = 'ObservationED'
        LEFT JOIN fhir_etl.uuid_namespace ns_procedure
            ON ns_procedure.name = 'ProcedureED'
)
INSERT INTO mimic_fhir.observation_ed
SELECT 
    uuid_OBSERVATION_ED AS id
    , uuid_SUBJECT_ID AS patient_id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Observation'
        , 'id', uuid_OBSERVATION_ED
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://fhir.mimic.mit.edu/StructureDefinition/mimic-observation-ed'
            )
        ) 
        , 'status', 'final'
        , 'category', jsonb_build_array(jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://terminology.hl7.org/CodeSystem/observation-category'  
                , 'code', 'exam'
                , 'display', 'Exam'
            ))
        ))
        -- Item code for observation-ed
        , 'code', jsonb_build_object(
            'coding', jsonb_build_array(
                CASE 
                    WHEN ed_KEY = 'rhythm' THEN
                        jsonb_build_object(
                            'system', 'http://loinc.org'
                            , 'code', '8884-9'
                            , 'display', 'Heart rate rhythm'
                        )   
                    WHEN ed_KEY = 'pain' THEN
                        jsonb_build_object(
                            'system', 'http://loinc.org'
                            , 'code', '98137-3'
                            , 'display', 'Pain assessment report'
                        ) 
                END
            )
        )
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'encounter', jsonb_build_object('reference', 'Encounter/' || uuid_STAY_ID)
        , 'effectiveDateTime', ed_CHARTTIME
        , 'dataAbsentReason', 
            CASE WHEN ed_VALUE IS NULL THEN
                jsonb_build_object(
                    'coding', jsonb_build_array(jsonb_build_object(
                        'system', 'http://terminology.hl7.org/CodeSystem/data-absent-reason'  
                        , 'code', 'unknown'
                        , 'display', 'Unknown'
                    ))
                )
            ELSE NULL END
        , 'valueString',
            CASE 
                WHEN ed_VALUE IS NULL THEN NULL
                ELSE ed_VALUE 
            END
        , 'partOf', jsonb_build_array(jsonb_build_object('reference', 'Procedure/' || uuid_PROCEDURE))
    )) AS fhir
FROM 
    fhir_observation_ed;

-- observations coming out of triage
WITH observation_ed AS (
    SELECT 
        tr.subject_id
        , tr.stay_id
        , x.*
    FROM mimic_ed.triage tr, jsonb_each_text(to_jsonb(tr)) AS x("key", value)
    WHERE KEY IN ('pain', 'acuity', 'chiefcomplaint' ) 
), fhir_observation_ed AS (
    SELECT
        ed.KEY AS ed_KEY
        , ed.value AS ed_VALUE
        , CAST(stay.intime AS TIMESTAMPTZ) AS stay_INTIME
        
        -- reference uuids
        , uuid_generate_v5(ns_observation_ed.uuid, ed.stay_id || '-' || stay.intime || '-' || ed.KEY || '-triage') as uuid_OBSERVATION_ED
        , uuid_generate_v5(ns_patient.uuid, CAST(ed.subject_id AS TEXT)) AS uuid_SUBJECT_ID
        , uuid_generate_v5(ns_encounter_ed.uuid, CAST(ed.stay_id AS TEXT)) AS uuid_STAY_ID
        , uuid_generate_v5(ns_procedure.uuid, CAST(ed.stay_id AS TEXT)) AS uuid_PROCEDURE
    FROM
        observation_ed ed
        INNER JOIN mimic_hosp.patients pat
            ON ed.subject_id = pat.subject_id
        LEFT JOIN mimic_ed.edstays stay
            ON ed.stay_id =  stay.stay_id
        LEFT JOIN fhir_etl.uuid_namespace ns_encounter_ed
            ON ns_encounter_ed.name = 'EncounterED'
        LEFT JOIN fhir_etl.uuid_namespace ns_patient
            ON ns_patient.name = 'Patient'
        LEFT JOIN fhir_etl.uuid_namespace ns_observation_ed
            ON ns_observation_ed.name = 'ObservationED'
        LEFT JOIN fhir_etl.uuid_namespace ns_procedure
            ON ns_procedure.name = 'ProcedureED'
)
INSERT INTO mimic_fhir.observation_ed
SELECT 
    uuid_OBSERVATION_ED AS id
    , uuid_SUBJECT_ID AS patient_id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Observation'
        , 'id', uuid_OBSERVATION_ED
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://fhir.mimic.mit.edu/StructureDefinition/mimic-observation-ed'
            )
        ) 
        , 'status', 'final'
        , 'category', jsonb_build_array(jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://terminology.hl7.org/CodeSystem/observation-category'  
                , 'code', 'survey'
                , 'display', 'Survey'
            ))
        ))
        -- Item code for observation-ed
        , 'code', jsonb_build_object(
            'coding', jsonb_build_array(
                CASE 
                    WHEN ed_KEY = 'acuity' THEN
                        jsonb_build_object(
                            'system', 'http://loinc.org'
                            , 'code', '56839-4'
                            , 'display', 'Acuity assessment Narrative'
                        )   
                    WHEN ed_KEY = 'chiefcomplaint' THEN
                        jsonb_build_object(
                            'system', 'http://loinc.org'
                            , 'code', '8661-1'
                            , 'display', 'Chief complaint - Reported'
                        ) 
                    WHEN ed_KEY = 'pain' THEN
                        jsonb_build_object(
                            'system', 'http://loinc.org'
                            , 'code', '98137-3'
                            , 'display', 'Pain assessment report'
                        ) 
                END
            )
        )
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'encounter', jsonb_build_object('reference', 'Encounter/' || uuid_STAY_ID)
        , 'effectiveDateTime', stay_INTIME
        , 'dataAbsentReason', 
            CASE WHEN ed_VALUE IS NULL THEN
                jsonb_build_array(jsonb_build_object(
                    'coding', jsonb_build_array(jsonb_build_object(
                        'system', 'http://terminology.hl7.org/CodeSystem/data-absent-reason'  
                        , 'code', 'unknown'
                        , 'display', 'Unknown'
                    ))
                ))
            ELSE NULL END
        , 'valueString',
            CASE 
                WHEN ed_VALUE IS NULL THEN NULL
                ELSE ed_VALUE 
            END
        , 'partOf', jsonb_build_array(jsonb_build_object('reference', 'Procedure/' || uuid_PROCEDURE))
    )) AS fhir
FROM 
    fhir_observation_ed;
