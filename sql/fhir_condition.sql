-- Purpose: Generate a FHIR Condition resource for each row in diagnosis_icd 
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit

DROP TABLE IF EXISTS mimic_fhir.condition;
CREATE TABLE mimic_fhir.condition(
    id          uuid PRIMARY KEY,
    patient_id  uuid NOT NULL,
    fhir        jsonb NOT NULL 
);

WITH fhir_condition AS (
    SELECT
        TRIM(diag.icd_code) AS diag_ICD_CODE
        , icd.long_title AS icd_LONG_TITLE
        , diag.icd_version AS diag_ICD_VERSION
        , CASE WHEN diag.icd_version = 9 
            THEN 'http://fhir.mimic.mit.edu/CodeSystem/mimic-diagnosis-icd9' 
            ELSE 'http://fhir.mimic.mit.edu/CodeSystem/mimic-diagnosis-icd10'
        END AS diag_ICD_SYSTEM
            
  
        -- reference uuids
        , uuid_generate_v5(ns_condition.uuid, diag.hadm_id || '-' || diag.seq_num || '-' || diag.icd_code) as uuid_DIAGNOSIS
        , uuid_generate_v5(ns_patient.uuid, CAST(diag.subject_id AS TEXT)) as uuid_SUBJECT_ID
        , uuid_generate_v5(ns_encounter.uuid, CAST(diag.hadm_id AS TEXT)) as uuid_HADM_ID
    FROM
        mimic_hosp.diagnoses_icd diag
        LEFT JOIN mimic_hosp.d_icd_diagnoses icd
            ON diag.icd_code = icd.icd_code
            AND diag.icd_version = icd.icd_version
        LEFT JOIN fhir_etl.uuid_namespace ns_encounter 
            ON ns_encounter.name = 'Encounter'
        LEFT JOIN fhir_etl.uuid_namespace ns_patient 
            ON ns_patient.name = 'Patient'
        LEFT JOIN fhir_etl.uuid_namespace ns_condition
            ON ns_condition.name = 'Condition'
)

INSERT INTO mimic_fhir.condition
SELECT 
    uuid_DIAGNOSIS as id
    , uuid_SUBJECT_ID AS patient_id 
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Condition'
        , 'id', uuid_DIAGNOSIS
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://fhir.mimic.mit.edu/StructureDefinition/mimic-condition'
            )
        )      
        -- All diagnoses in MIMIC are considered encounter derived
        , 'category', jsonb_build_array(jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://terminology.hl7.org/CodeSystem/condition-category'  
                , 'code', 'encounter-diagnosis'
                , 'display', 'Encounter Diagnosis'
            ))
        ))
        , 'code', jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', diag_ICD_SYSTEM
                , 'code', diag_ICD_CODE
                , 'display', icd_LONG_TITLE
            ))
        )
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'encounter', jsonb_build_object('reference', 'Encounter/' || uuid_HADM_ID) 
    )) as fhir 
FROM
    fhir_condition
