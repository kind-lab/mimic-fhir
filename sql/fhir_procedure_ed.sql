-- Purpose: Generate a FHIR Procedure resource for each procedures_icd row
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit

SELECT fhir_etl.fn_create_table_patient_dependent('procedure_ed');

-- triage information
WITH fhir_procedure_triage AS (
    SELECT
        CAST(stay.intime AS TIMESTAMPTZ) AS stay_INTIME
    
        -- reference uuids
        , uuid_generate_v5(ns_procedure.uuid, CAST(proc.stay_id AS TEXT)) AS uuid_PROCEDURE_ID
        , uuid_generate_v5(ns_patient.uuid, CAST(proc.subject_id AS TEXT)) AS uuid_SUBJECT_ID
        , uuid_generate_v5(ns_encounter.uuid, CAST(proc.stay_id AS TEXT)) AS uuid_STAY_ID
    FROM
        mimic_ed.triage proc
        INNER JOIN mimiciv_hosp.patients pat
            ON proc.subject_id = pat.subject_id
        LEFT JOIN mimic_ed.edstays stay
            ON proc.stay_id = stay.stay_id
        LEFT JOIN fhir_etl.uuid_namespace ns_encounter
            ON ns_encounter.name = 'EncounterED'
        LEFT JOIN fhir_etl.uuid_namespace ns_patient
            ON ns_patient.name = 'Patient'
        LEFT JOIN fhir_etl.uuid_namespace ns_procedure
            ON ns_procedure.name = 'ProcedureED'
)

INSERT INTO mimic_fhir.procedure_ed
SELECT 
    uuid_PROCEDURE_ID AS id
    , uuid_SUBJECT_ID AS patient_id 
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Procedure'
        , 'id', uuid_PROCEDURE_ID
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-procedure-ed'
            )
        )  
        , 'status', 'completed' -- All procedures are considered complete        
        , 'code', jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://snomed.info/sct'
                , 'code', '386478007'
                , 'display', 'Triage: emergency center (procedure)'
            ))
        )
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'encounter', jsonb_build_object('reference', 'Encounter/' || uuid_STAY_ID) 
        , 'performedDateTime', stay_INTIME
    )) AS fhir 
FROM
    fhir_procedure_triage;

-- vitalsign information
WITH fhir_procedure_vitalsign AS (
    SELECT
        CAST(proc.charttime  AS TIMESTAMPTZ) AS proc_CHARTTIME
  
        -- reference uuids
        , uuid_generate_v5(ns_procedure.uuid, proc.stay_id || '-' || proc.charttime) AS uuid_PROCEDURE_ID
        , uuid_generate_v5(ns_patient.uuid, CAST(proc.subject_id AS TEXT)) AS uuid_SUBJECT_ID
        , uuid_generate_v5(ns_encounter.uuid, CAST(proc.stay_id AS TEXT)) AS uuid_STAY_ID
    FROM
        mimic_ed.vitalsign proc
        INNER JOIN mimiciv_hosp.patients pat
            ON proc.subject_id = pat.subject_id
        LEFT JOIN fhir_etl.uuid_namespace ns_encounter
            ON ns_encounter.name = 'EncounterED'
        LEFT JOIN fhir_etl.uuid_namespace ns_patient
            ON ns_patient.name = 'Patient'
        LEFT JOIN fhir_etl.uuid_namespace ns_procedure
            ON ns_procedure.name = 'ProcedureED'
)

INSERT INTO mimic_fhir.procedure_ed
SELECT 
    uuid_PROCEDURE_ID AS id
    , uuid_SUBJECT_ID AS patient_id 
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Procedure'
        , 'id', uuid_PROCEDURE_ID
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-procedure-ed'
            )
        ) 
        , 'status', 'completed' -- All procedures are considered complete        
        , 'code', jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://snomed.info/sct'
                , 'code', '410188000'
                , 'display', 'Taking patient vital signs assessment (procedure)'
            ))
        )
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'encounter', jsonb_build_object('reference', 'Encounter/' || uuid_STAY_ID) 
        , 'performedDateTime', proc_CHARTTIME

    )) AS fhir 
FROM
    fhir_procedure_vitalsign;
