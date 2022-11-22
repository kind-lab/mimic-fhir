-- Purpose: Generate a FHIR MedicationStatementresource for each row in medrecon 
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit


SELECT fhir_etl.fn_create_table_patient_dependent('medication_statement_ed');


WITH fhir_medication_statement_ed AS (
    SELECT 
        -- unique id for medication statement needs name, gsn, and ndc since gsn/ndc = 0 if missing. 
        -- And the same med name can have different gsn/ndc entries 
        gsn AS med_GSN
        , ndc AS med_NDC
        , med.name AS med_NAME
        , STRING_AGG(
            CAST(CASE WHEN etccode IS NOT NULL THEN 
                jsonb_build_object(
                    'code', etccode
                    , 'display', etcdescription
                    , 'system', 'http://mimic.mit.edu/fhir/mimic/CodeSystem/mimic-medication-etc'                
                ) 
            ELSE NULL END AS TEXT), ',')  AS med_ETC_CODES
        
        , CAST(med.charttime AS TIMESTAMPTZ) AS med_CHARTTIME
        
        -- reference uuids
        , uuid_generate_v5(ns_medication_statement.uuid, stay_id || '-' || charttime || '-' || med.name || '-' || gsn || '-' || ndc) AS uuid_MEDICATION_STATEMENT
        , uuid_generate_v5(ns_patient.uuid, CAST(MAX(med.subject_id) AS TEXT)) AS uuid_SUBJECT_ID
        , uuid_generate_v5(ns_encounter.uuid, CAST(med.stay_id AS TEXT)) AS uuid_STAY_ID
    FROM 
        mimic_ed.medrecon med
        INNER JOIN mimiciv_hosp.patients pat
            ON med.subject_id = pat.subject_id
        
        -- UUID namespaces
        LEFT JOIN fhir_etl.uuid_namespace ns_encounter
            ON ns_encounter.name = 'EncounterED'
        LEFT JOIN fhir_etl.uuid_namespace ns_patient
            ON ns_patient.name = 'Patient'
        LEFT JOIN fhir_etl.uuid_namespace ns_medication_statement
            ON ns_medication_statement.name = 'MedicationStatementED'
    GROUP BY 
        stay_id
        , charttime
        , med.name
        , gsn
        , ndc
         -- uuid cannot be maxed... so need to GROUP 
        , ns_medication_statement.uuid
        , ns_patient.uuid
        , ns_encounter.uuid
) 

INSERT INTO mimic_fhir.medication_statement_ed
SELECT
    uuid_MEDICATION_STATEMENT AS id
    , uuid_SUBJECT_ID AS patient_id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'MedicationStatement'
        , 'id', uuid_MEDICATION_STATEMENT
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-medication-statement-ed'
            )
         ) 
        , 'status', 'unknown' -- UNKNOWN, NOT stated IN MIMIC
        , 'medicationCodeableConcept', 
            CASE WHEN med_GSN = '0' AND med_NDC = '0' AND med_ETC_CODES ='[null]' THEN
                jsonb_build_object('text', med_NAME)
            ELSE
                jsonb_build_object(
                    'text', med_NAME
                    , 'coding', fhir_etl.fn_med_statement(med_GSN, med_NDC, med_ETC_CODES)
                )
            END
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'context', jsonb_build_object('reference', 'Encounter/' || uuid_STAY_ID) 
        , 'dateAsserted', med_CHARTTIME

    )) AS fhir  
FROM 
    fhir_medication_statement_ed;
