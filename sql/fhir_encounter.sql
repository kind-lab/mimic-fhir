-- Purpose: Generate an FHIR Encounter resource for each row in admissions
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit

DROP TABLE IF EXISTS mimic_fhir.encounter;
CREATE TABLE mimic_fhir.encounter(
    id          uuid PRIMARY KEY,
    patient_id  uuid NOT NULL,
    fhir        jsonb NOT NULL 
);

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
        mimic_core.transfers tfr 
        INNER JOIN fhir_etl.subjects sub
            ON tfr.subject_id = sub.subject_id
        LEFT JOIN fhir_etl.uuid_namespace ns_location
            ON ns_location.name = 'Location'
    WHERE tfr.careunit IS NOT NULL 
    GROUP BY hadm_id    
), fhir_encounter AS (
    SELECT 
        CAST(adm.hadm_id AS TEXT) AS adm_HADM_ID	
        , adm.admission_type AS adm_ADMISSION_TYPE
        , CAST(adm.admittime AS TIMESTAMPTZ) AS adm_ADMITTIME
        , CAST(adm.dischtime AS TIMESTAMPTZ) AS adm_DISCHTIME
        , adm.admission_location AS adm_ADMISSION_LOCATION  		
        , adm.discharge_location AS adm_DISCHARGE_LOCATION  
        , tfr.location_array AS tfr_LOCATION_ARRAY
  	
        -- reference uuids
        , uuid_generate_v5(ns_encounter.uuid, CAST(adm.hadm_id AS TEXT)) AS uuid_HADM_ID
        , uuid_generate_v5(ns_patient.uuid, CAST(adm.subject_id AS TEXT)) AS uuid_SUBJECT_ID
        , uuid_generate_v5(ns_organization.uuid, 'http://hl7.org/fhir/sid/us-npi/1194052720') AS uuid_ORG
    FROM 
        mimic_core.admissions adm
        INNER JOIN fhir_etl.subjects sub
            ON adm.subject_id = sub.subject_id 
        LEFT JOIN transfer_locations tfr
            ON adm.hadm_id = tfr.hadm_id
        LEFT JOIN fhir_etl.uuid_namespace ns_encounter	
            ON ns_encounter.name = 'Encounter'
        LEFT JOIN fhir_etl.uuid_namespace ns_patient	
            ON ns_patient.name = 'Patient'
        LEFT JOIN fhir_etl.uuid_namespace ns_organization	
            ON ns_organization.name = 'Organization'
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
                'http://fhir.mimic.mit.edu/StructureDefinition/mimic-encounter'
            )
        ) 
        , 'identifier', jsonb_build_array(jsonb_build_object(
                'value', adm_HADM_ID
                , 'system', 'http://fhir.mimic.mit.edu/identifier/encounter'
                , 'use', 'usual'
                , 'assigner', jsonb_build_object('reference', 'Organization/' || uuid_ORG)
        ))	
        , 'status', 'finished' -- ALL encounters assumed finished
        , 'class', jsonb_build_object(
            'system', 'http://fhir.mimic.mit.edu/CodeSystem/admission-class'
            , 'code', adm_ADMISSION_TYPE
        )
        , 'type', jsonb_build_array(jsonb_build_object(
            'coding', jsonb_build_array(json_build_object(
                'system', 'http://fhir.mimic.mit.edu/CodeSystem/admission-type'
                , 'code', adm_ADMISSION_TYPE
            ))
        ))
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
                        'system', 'http://fhir.mimic.mit.edu/CodeSystem/admit-source'
                        , 'code', adm_ADMISSION_LOCATION
                    ))                
                ) ELSE NULL END
        , 'dischargeDisposition', 
            CASE WHEN adm_DISCHARGE_LOCATION IS NOT NULL
                THEN jsonb_build_object(
                    'coding',  jsonb_build_array(jsonb_build_object(
                        'system', 'http://fhir.mimic.mit.edu/CodeSystem/discharge-disposition'
                        , 'code', adm_DISCHARGE_LOCATION
                    ))                
                ) ELSE NULL END
        )   
        , 'location', tfr_LOCATION_ARRAY
        , 'serviceProvider', jsonb_build_object('reference', 'Organization/' || uuid_ORG)	 		
    )) AS fhir
FROM 
    fhir_encounter 
