DROP TABLE IF EXISTS mimic_fhir.observation_micro_susc;
CREATE TABLE mimic_fhir.observation_micro_susc(
    id          uuid PRIMARY KEY,
    patient_id  uuid NOT NULL,
    fhir        jsonb NOT NULL 
);

WITH fhir_observation_micro_susc AS (
    SELECT 
        mi.micro_specimen_id  AS mi_MICRO_SPECIMEN_ID
        , mi.micro_specimen_id || '-' ||  mi.org_itemid || '-' ||  
            mi.isolate_num || '-' ||  mi.ab_itemid AS id_MICRO_SUSC
        , CAST(mi.ab_itemid AS TEXT) AS mi_AB_ITEMID
        , mi.ab_name AS mi_AB_NAME
        , mi.subject_id AS mi_SUBJECT_ID
        , mi.interpretation AS mi_INTERPRETATION
        , CAST(mi.storetime AS TIMESTAMPTZ) AS mi_STORETIME
        , mi.comments AS mi_COMMENTS
        
        -- dilution details
        , mi.dilution_value AS mi_DILUTION_VALUE
        , CASE 
            WHEN TRIM(mi.dilution_comparison) = '=>' THEN '>='
            WHEN TRIM(mi.dilution_comparison) = '<=' THEN '<='
            WHEN TRIM(mi.dilution_comparison) = '=' THEN NULL -- In fhir assumed equal if no comparator
            ELSE NULL END       
        AS mi_DILUTION_COMPARISON

        -- UUID references
        , uuid_generate_v5(
            ns_observation_micro_susc.uuid 
            , mi.micro_specimen_id || '-' ||  mi.org_itemid || '-' ||  
                mi.isolate_num || '-' ||  mi.ab_itemid
        ) AS uuid_MICRO_SUSC
        , uuid_generate_v5(ns_observation_micro_org.uuid, mi.test_itemid || '-' || mi.micro_specimen_id || '-' || mi.org_itemid) AS uuid_MICRO_ORG
        , uuid_generate_v5(ns_patient.uuid, CAST(mi.subject_id AS TEXT)) as uuid_SUBJECT_ID 
    FROM 
        mimic_hosp.microbiologyevents mi
        INNER JOIN fhir_etl.subjects sub
            ON mi.subject_id = sub.subject_id 
        LEFT JOIN fhir_etl.uuid_namespace ns_patient
            ON ns_patient.name = 'Patient'
        LEFT JOIN fhir_etl.uuid_namespace ns_observation_micro_org
            ON ns_observation_micro_org.name = 'ObservationMicroOrg'
        LEFT JOIN fhir_etl.uuid_namespace ns_observation_micro_susc
            ON ns_observation_micro_susc.name = 'ObservationMicroSusc'
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
                'http://fhir.mimic.mit.edu/StructureDefinition/mimic-observation-micro-susc'
            )
        ) 
        , 'identifier',  jsonb_build_array(jsonb_build_object(
            'value', id_MICRO_SUSC
            , 'system', 'http://fhir.mimic.mit.edu/identifier/observation-micro-susc'
        ))  
        , 'status', 'final'        
        , 'category', jsonb_build_array(jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://terminology.hl7.org/CodeSystem/observation-category'  
                , 'code', 'laboratory'
            ))
        ))
        , 'code', jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://fhir.mimic.mit.edu/CodeSystem/microbiology-antibiotic'  
                , 'code', mi_AB_ITEMID
                , 'display', mi_AB_NAME
            ))
        )
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'effectiveDateTime', mi_STORETIME
        , 'valueCodeableConcept', jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://fhir.mimic.mit.edu/CodeSystem/microbiology-interpretation'  
                , 'code', mi_INTERPRETATION
            ))
        )
        , 'derivedFrom', jsonb_build_array(jsonb_build_object('reference', 'Observation/' || uuid_MICRO_ORG)) 
        , 'note', jsonb_build_array(jsonb_build_object(
            'text',  mi_COMMENTS
        ))
        , 'extension', CASE
            WHEN mi_DILUTION_COMPARISON IS NOT NULL THEN
                jsonb_build_array(jsonb_build_object(
                    'url', 'http://fhir.mimic.mit.edu/StructureDefinition/dilution-details'
                    , 'valueQuantity', jsonb_build_object(
                        'value', mi_DILUTION_VALUE
                        , 'comparator', mi_DILUTION_COMPARISON
                     )
                ))
            -- Comparator is not present or set to '=', which gets omitted in fhir. Just store value
            WHEN mi_DILUTION_VALUE IS NOT NULL THEN 
                jsonb_build_array(jsonb_build_object(
                    'url', 'http://fhir.mimic.mit.edu/StructureDefinition/dilution-details'
                    , 'valueQuantity', jsonb_build_object(
                        'value', mi_DILUTION_VALUE
                     )
                ))
            ELSE NULL END 
      
        
    )) AS fhir
FROM
    fhir_observation_micro_susc
