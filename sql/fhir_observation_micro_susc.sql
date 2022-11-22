SELECT fhir_etl.fn_create_table_patient_dependent('observation_micro_susc');

WITH fhir_observation_micro_susc AS (
    SELECT
        mi.micro_specimen_id  AS mi_MICRO_SPECIMEN_ID
        , CAST(mi.microevent_id AS TEXT) AS id_MICRO_SUSC
        , CAST(mi.ab_itemid AS TEXT) AS mi_AB_ITEMID
        , mi.ab_name AS mi_AB_NAME
        , mi.subject_id AS mi_SUBJECT_ID
        , CAST(mi.storetime AS TIMESTAMPTZ) AS mi_STORETIME
        , mi.comments AS mi_COMMENTS
        , interp.fhir_interpretation_code AS interp_FHIR_INTERPRETATION_CODE
        , interp.fhir_interpretation_display AS interp_FHIR_INTERPRETATION_DISPLAY
        
        -- dilution details
        , mi.dilution_value AS mi_DILUTION_VALUE
        , CASE 
            WHEN TRIM(mi.dilution_comparison) = '=>' THEN '>='
            WHEN TRIM(mi.dilution_comparison) = '<=' THEN '<='
            WHEN TRIM(mi.dilution_comparison) = '=' THEN NULL -- In fhir assumed equal if no comparator
            ELSE NULL END
        AS mi_DILUTION_COMPARISON

        -- UUID references
        , uuid_generate_v5(ns_observation_micro_susc.uuid, CAST(mi.microevent_id AS TEXT)) AS uuid_MICRO_SUSC
        , uuid_generate_v5(ns_observation_micro_org.uuid, mi.test_itemid || '-' || mi.micro_specimen_id || '-' || mi.org_itemid) AS uuid_MICRO_ORG
        , uuid_generate_v5(ns_patient.uuid, CAST(mi.subject_id AS TEXT)) as uuid_SUBJECT_ID 
    FROM 
        mimiciv_hosp.microbiologyevents mi
        LEFT JOIN fhir_etl.uuid_namespace ns_patient
            ON ns_patient.name = 'Patient'
        LEFT JOIN fhir_etl.uuid_namespace ns_observation_micro_org
            ON ns_observation_micro_org.name = 'ObservationMicroOrg'
        LEFT JOIN fhir_etl.uuid_namespace ns_observation_micro_susc
            ON ns_observation_micro_susc.name = 'ObservationMicroSusc'
        -- mappings
        LEFT JOIN fhir_etl.map_micro_interpretation interp
            ON mi.interpretation = interp.mimic_interpretation
    WHERE 
        mi.ab_itemid IS NOT NULL
)

INSERT INTO mimic_fhir.observation_micro_susc  
SELECT 
    uuid_MICRO_SUSC AS id
    , uuid_SUBJECT_ID AS patient_id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Observation'
        , 'id', uuid_MICRO_SUSC 
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-observation-micro-susc'
            )
        ) 
        , 'identifier',  jsonb_build_array(jsonb_build_object(
            'value', id_MICRO_SUSC
            , 'system', 'http://mimic.mit.edu/fhir/mimic/identifier/observation-micro-susc'
        ))  
        , 'status', 'final'        
        , 'category', jsonb_build_array(jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://terminology.hl7.org/CodeSystem/observation-category'  
                , 'code', 'laboratory'
                , 'display', 'Laboratory'
            ))
        ))
        , 'code', jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://mimic.mit.edu/fhir/mimic/CodeSystem/mimic-microbiology-antibiotic'  
                , 'code', mi_AB_ITEMID
                , 'display', mi_AB_NAME
            ))
        )
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'effectiveDateTime', mi_STORETIME
        , 'valueCodeableConcept', jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation'  
                , 'code', interp_FHIR_INTERPRETATION_CODE
                , 'display', interp_FHIR_INTERPRETATION_DISPLAY
            ))
        )
        , 'derivedFrom', jsonb_build_array(jsonb_build_object('reference', 'Observation/' || uuid_MICRO_ORG)) 
        , 'note', CASE WHEN mi_COMMENTS IS NOT NULL THEN
            jsonb_build_array(jsonb_build_object(
                'text',  mi_COMMENTS
            ))
        ELSE NULL END
        , 'extension', CASE
            WHEN mi_DILUTION_COMPARISON IS NOT NULL THEN
                jsonb_build_array(jsonb_build_object(
                    'url', 'http://mimic.mit.edu/fhir/mimic/StructureDefinition/dilution-details'
                    , 'valueQuantity', jsonb_build_object(
                        'value', mi_DILUTION_VALUE
                        , 'comparator', mi_DILUTION_COMPARISON
                     )
                ))
            -- Comparator is not present or set to '=', which gets omitted in fhir. Just store value
            WHEN mi_DILUTION_VALUE IS NOT NULL THEN 
                jsonb_build_array(jsonb_build_object(
                    'url', 'http://mimic.mit.edu/fhir/mimic/StructureDefinition/dilution-details'
                    , 'valueQuantity', jsonb_build_object(
                        'value', mi_DILUTION_VALUE
                     )
                ))
            ELSE NULL END
    )) AS fhir
FROM
    fhir_observation_micro_susc