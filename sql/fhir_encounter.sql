-- Purpose: Generate an FHIR Encounter resource for each row in admissions
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit

SELECT fhir_etl.fn_create_table_patient_dependent('encounter');

-- Store the careunit transfer history
WITH transfer_locations AS (
     SELECT 
        hadm_id
        , jsonb_agg(
            jsonb_build_object(
                'location', jsonb_build_object(
                    'reference', 'Location/' || uuid_generate_v5(ns_location.uuid, careunit)
                ) 
                , 'period', jsonb_build_object(
                    'start', CAST(tfr.intime AS TIMESTAMPTZ)
                    , 'end', CAST(tfr.outtime AS TIMESTAMPTZ)
                )
            )
        ORDER BY intime) AS location_array
    FROM 
        mimiciv_hosp.transfers tfr 
        LEFT JOIN fhir_etl.uuid_namespace ns_location
            ON ns_location.name = 'Location'
    WHERE tfr.careunit IS NOT NULL 
    GROUP BY hadm_id    
), cpt_codes AS (
    SELECT 
        adm.hadm_id
        , jsonb_agg(
            jsonb_build_object(
                'coding', jsonb_build_array(json_build_object(
                    'system', 'http://mimic.mit.edu/fhir/mimic/CodeSystem/mimic-hcpcs-cd'
                    , 'code', cpt.hcpcs_cd
                    , 'display', cpt.short_description
                ))
            )
        ) AS cpt_ARRAY
    FROM 
        mimiciv_hosp.admissions adm
        LEFT JOIN mimiciv_hosp.hcpcsevents cpt
            ON adm.hadm_id = cpt.hadm_id
    WHERE cpt.hcpcs_cd IS NOT NULL 
    GROUP BY adm.hadm_id     
), first_service AS (
    WITH services AS (
        SELECT 
            hadm_id
            , curr_service
            , ROW_NUMBER() OVER (PARTITION BY hadm_id ORDER BY transfertime ASC) row_num
        FROM mimiciv_hosp.services s 
    )
    SELECT 
        hadm_id
        , curr_service
    FROM services
    WHERE row_num = 1
),fhir_encounter AS (
    SELECT 
        CAST(adm.hadm_id AS TEXT) AS adm_HADM_ID	
        , cls.fhir_class_code AS cls_FHIR_CLASS_CODE
        , cls.fhir_class_display AS cls_FHIR_CLASS_DISPLAY
        , pry.fhir_priority_code AS pry_FHIR_PRIORITY_CODE
        , pry.fhir_priority_display AS pry_FHIR_PRIORITY_DISPLAY
        , CAST(adm.admittime AS TIMESTAMPTZ) AS adm_ADMITTIME
        , CAST(adm.dischtime AS TIMESTAMPTZ) AS adm_DISCHTIME
        , adm.admission_location AS adm_ADMISSION_LOCATION  		
        , adm.discharge_location AS adm_DISCHARGE_LOCATION  
        , tfr.location_array AS tfr_LOCATION_ARRAY
        , cpt.cpt_ARRAY AS cpt_ARRAY
        , serv.curr_service AS serv_CURR_SERVICE
  	
        -- reference uuids
        , uuid_generate_v5(ns_encounter.uuid, CAST(adm.hadm_id AS TEXT)) AS uuid_HADM_ID
        , uuid_generate_v5(ns_patient.uuid, CAST(adm.subject_id AS TEXT)) AS uuid_SUBJECT_ID
        , uuid_generate_v5(ns_organization.uuid, 'http://hl7.org/fhir/sid/us-npi/1194052720') AS uuid_ORG
    FROM 
        mimiciv_hosp.admissions adm
        LEFT JOIN transfer_locations tfr
            ON adm.hadm_id = tfr.hadm_id
        LEFT JOIN cpt_codes cpt
            ON adm.hadm_id = cpt.hadm_id
        LEFT JOIN first_service serv
            ON adm.hadm_id = serv.hadm_id
        LEFT JOIN fhir_etl.uuid_namespace ns_encounter	
            ON ns_encounter.name = 'Encounter'
        LEFT JOIN fhir_etl.uuid_namespace ns_patient	
            ON ns_patient.name = 'Patient'
        LEFT JOIN fhir_etl.uuid_namespace ns_organization	
            ON ns_organization.name = 'Organization'
            
        -- mappings
        LEFT JOIN fhir_etl.map_encounter_class cls
            ON adm.admission_type = cls.mimic_class
        LEFT JOIN fhir_etl.map_encounter_priority pry
            ON adm.admission_type = pry.mimic_priority
)

INSERT INTO mimic_fhir.encounter
SELECT  
    uuid_HADM_ID AS id
    , uuid_SUBJECT_ID AS patient_id 
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Encounter'
        , 'id', uuid_HADM_ID
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-encounter'
            )
        ) 
        , 'identifier', jsonb_build_array(jsonb_build_object(
                'value', adm_HADM_ID
                , 'system', 'http://mimic.mit.edu/fhir/mimic/identifier/encounter-hosp'
                , 'use', 'usual'
                , 'assigner', jsonb_build_object('reference', 'Organization/' || uuid_ORG)
        ))	
        , 'status', 'finished' -- ALL encounters assumed finished
        , 'class', jsonb_build_object(
            'system', 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
            , 'code', cls_FHIR_CLASS_CODE
            , 'display', cls_FHIR_CLASS_DISPLAY
        )
        , 'type', 
            CASE WHEN cpt_ARRAY IS NOT NULL THEN 
                cpt_ARRAY
            ELSE
                jsonb_build_array(jsonb_build_object(
                    'coding', jsonb_build_array(json_build_object(
                        'system', 'http://snomed.info/sct'
                        , 'code', '308335008'
                        , 'display', 'Patient encounter procedure'
                    ))
                ))
            END
        , 'priority', jsonb_build_object(
            'coding', jsonb_build_array(json_build_object(
                'system', 'http://terminology.hl7.org/CodeSystem/v3-ActPriority'
                , 'code', pry_FHIR_PRIORITY_CODE
                , 'display', pry_FHIR_PRIORITY_DISPLAY
            ))
        )
        , 'serviceType', jsonb_build_object(
            'coding', jsonb_build_array(json_build_object(
                'system', 'http://mimic.mit.edu/fhir/mimic/CodeSystem/mimic-services'
                , 'code', serv_CURR_SERVICE
            ))
        )
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'period', jsonb_build_object(
            'start', adm_ADMITTIME
            , 'end', adm_DISCHTIME
        )
        , 'hospitalization', jsonb_build_object(
            'admitSource', 
                CASE WHEN adm_ADMISSION_LOCATION IS NOT NULL
                THEN jsonb_build_object(
                    'coding',  jsonb_build_array(jsonb_build_object(
                        'system', 'http://mimic.mit.edu/fhir/mimic/CodeSystem/mimic-admit-source'
                        , 'code', adm_ADMISSION_LOCATION
                    ))                
                ) ELSE NULL END
        , 'dischargeDisposition', 
            CASE WHEN adm_DISCHARGE_LOCATION IS NOT NULL
                THEN jsonb_build_object(
                    'coding',  jsonb_build_array(jsonb_build_object(
                        'system', 'http://mimic.mit.edu/fhir/mimic/CodeSystem/mimic-discharge-disposition'
                        , 'code', adm_DISCHARGE_LOCATION
                    ))                
                ) ELSE NULL END
        )   
        , 'location', tfr_LOCATION_ARRAY
        , 'serviceProvider', jsonb_build_object('reference', 'Organization/' || uuid_ORG)	 		
    )) AS fhir
FROM 
    fhir_encounter;
