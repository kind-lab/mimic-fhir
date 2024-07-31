-- Purpose: Generate a FHIR Condition resource for each row in diagnosis_icd 
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit

SELECT fhir_etl.fn_create_table_patient_dependent('condition');

WITH fhir_condition AS (
    SELECT
        CASE WHEN diag.icd_version = 9
            THEN cs_diagnosis_icd9.code
            ELSE cs_diagnosis_icd10.code
        END AS diag_ICD_CODE
        , CASE WHEN diag.icd_version = 9
            THEN cs_diagnosis_icd9.display
            ELSE cs_diagnosis_icd10.display
        END AS icd_DISPLAY
        , diag.icd_version AS diag_ICD_VERSION
        , CASE WHEN diag.icd_version = 9 
            THEN 'http://mimic.mit.edu/fhir/mimic/CodeSystem/mimic-diagnosis-icd9' 
            ELSE 'http://mimic.mit.edu/fhir/mimic/CodeSystem/mimic-diagnosis-icd10'
        END AS diag_ICD_SYSTEM

        -- reference uuids
        , uuid_generate_v5(ns_condition.uuid, diag.hadm_id || '-' || diag.seq_num || '-' || diag.icd_code) as uuid_DIAGNOSIS
        , uuid_generate_v5(ns_patient.uuid, CAST(diag.subject_id AS TEXT)) as uuid_SUBJECT_ID
        , uuid_generate_v5(ns_encounter.uuid, CAST(diag.hadm_id AS TEXT)) as uuid_HADM_ID
    FROM
        mimiciv_hosp.diagnoses_icd diag
        LEFT JOIN mimiciv_hosp.d_icd_diagnoses icd
            ON diag.icd_code = icd.icd_code
            AND diag.icd_version = icd.icd_version

        -- code systems : join to fhir-trm cs_diagnosis_icd9 and cs_diagnosis_icd10
        LEFT OUTER JOIN fhir_trm.cs_diagnosis_icd9 AS cs_diagnosis_icd9
            ON TRIM(diag.icd_code) = cs_diagnosis_icd9.code
            AND diag.icd_version = 9

        LEFT OUTER JOIN fhir_trm.cs_diagnosis_icd10 AS cs_diagnosis_icd10
            ON TRIM(diag.icd_code) = cs_diagnosis_icd10.code
            AND diag.icd_version = 10


        -- UUID namespaces
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
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-condition'
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
                , 'display', icd_DISPLAY
            ))
        )
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'encounter', jsonb_build_object('reference', 'Encounter/' || uuid_HADM_ID) 
    )) as fhir 
FROM
    fhir_condition;
