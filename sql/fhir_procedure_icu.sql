-- Purpose: Generate a FHIR Procedure for each row in procedureevents
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit

SELECT fhir_etl.fn_create_table_patient_dependent('procedure_icu');

WITH fhir_procedure_icu AS (
    SELECT
        pe.ordercategoryname AS pe_ORDERCATEGORYNAME
        , CAST(pe.itemid AS TEXT) AS pe_ITEMID
        , CAST(pe.starttime AS TIMESTAMPTZ) AS pe_STARTTIME
        , CAST(pe.endtime AS TIMESTAMPTZ) AS pe_ENDTIME
        , TRIM(REGEXP_REPLACE(pe.location, '\s+', ' ', 'g')) AS pe_LOCATION
        , di.label AS di_LABEL
        , map_status.fhir_status AS fhir_STATUS
  
        -- refernce uuids
        , uuid_generate_v5(ns_procedure_icu.uuid, pe.stay_id || '-' || pe.orderid || '-' || pe.itemid) AS uuid_PROCEDUREEVENT
        , uuid_generate_v5(ns_patient.uuid, CAST(pe.subject_id AS TEXT)) AS uuid_SUBJECT_ID
        , uuid_generate_v5(ns_encounter_icu.uuid, CAST(pe.stay_id AS TEXT)) AS uuid_STAY_ID
    FROM
        mimiciv_icu.procedureevents pe
        LEFT JOIN mimiciv_icu.d_items di
            ON pe.itemid = di.itemid
        LEFT JOIN fhir_etl.map_status_procedure_icu map_status
            ON pe.statusdescription = map_status.mimic_status
        LEFT JOIN fhir_etl.uuid_namespace ns_encounter_icu
            ON ns_encounter_icu.name = 'EncounterICU'
        LEFT JOIN fhir_etl.uuid_namespace ns_patient
            ON ns_patient.name = 'Patient'
        LEFT JOIN fhir_etl.uuid_namespace ns_procedure_icu
            ON ns_procedure_icu.name = 'ProcedureICU'
)

INSERT INTO mimic_fhir.procedure_icu
SELECT 
    uuid_PROCEDUREEVENT AS id
    , uuid_SUBJECT_ID AS patient_id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Procedure'
        , 'id', uuid_PROCEDUREEVENT
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-procedure-icu'
            )
        )
        , 'status', fhir_STATUS
        , 'category', jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://mimic.mit.edu/fhir/mimic/CodeSystem/mimic-procedure-category'  
                , 'code', pe_ORDERCATEGORYNAME
            ))
        )
        -- Procedure item codes
        , 'code', jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://mimic.mit.edu/fhir/mimic/CodeSystem/mimic-d-items'  
                , 'code', pe_ITEMID
                , 'display', di_LABEL
            ))
        )
        -- Body location where procedure was applied  
        , 'bodySite',
            CASE WHEN pe_LOCATION IS NOT NULL THEN
                jsonb_build_array(jsonb_build_object(
                    'coding', jsonb_build_array(jsonb_build_object(
                        'system', 'http://mimic.mit.edu/fhir/mimic/CodeSystem/mimic-bodysite'
                        , 'code', pe_LOCATION
                    ))
                ))
            ELSE NULL END
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'encounter', jsonb_build_object('reference', 'Encounter/' || uuid_STAY_ID)
        , 'performedPeriod', jsonb_build_object(
            'start', pe_STARTTIME
            , 'end', pe_ENDTIME
        )
    )) AS fhir
FROM
    fhir_procedure_icu;
