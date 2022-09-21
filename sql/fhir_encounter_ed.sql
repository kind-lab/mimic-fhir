-- Purpose: Generate an FHIR Encounter resource for each row in edstays
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit

DROP TABLE IF EXISTS mimic_fhir.encounter_ed;
CREATE TABLE mimic_fhir.encounter_ed(
    id          uuid PRIMARY KEY,
    patient_id  uuid NOT NULL,
    fhir        jsonb NOT NULL 
);

-- Store the careunit transfer history
WITH fhir_encounter_ed AS (
    SELECT 
        CAST(ed.stay_id AS TEXT) AS ed_STAY_ID	
        , CAST(ed.intime AS TIMESTAMPTZ) AS ed_INTIME
        , CAST(ed.outtime AS TIMESTAMPTZ) AS ed_OUTTIME
        , arrival_transport AS ed_ARRIVAL_TRANSPORT
        , disposition AS ed_DISPOSITION
  	
        -- reference uuids
        , uuid_generate_v5(ns_encounter.uuid, CAST(ed.hadm_id AS TEXT)) AS uuid_HADM_ID
        , uuid_generate_v5(ns_encounter_ed.uuid, CAST(ed.stay_id AS TEXT)) AS uuid_STAY_ID
        , uuid_generate_v5(ns_patient.uuid, CAST(ed.subject_id AS TEXT)) AS uuid_SUBJECT_ID
        , uuid_generate_v5(ns_organization.uuid, 'http://hl7.org/fhir/sid/us-npi/1194052720') AS uuid_ORG
    FROM 
        mimic_ed.edstays ed
        INNER JOIN mimic_hosp.patients pat
            ON ed.subject_id = pat.subject_id
        LEFT JOIN fhir_etl.uuid_namespace ns_encounter	
            ON ns_encounter.name = 'Encounter'
        LEFT JOIN fhir_etl.uuid_namespace ns_encounter_ed 
            ON ns_encounter_ed.name = 'EncounterED'
        LEFT JOIN fhir_etl.uuid_namespace ns_patient	
            ON ns_patient.name = 'Patient'
        LEFT JOIN fhir_etl.uuid_namespace ns_organization	
            ON ns_organization.name = 'Organization'
)

INSERT INTO mimic_fhir.encounter_ed
SELECT  
    uuid_STAY_ID AS id
    , uuid_SUBJECT_ID AS patient_id 
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Encounter'
        , 'id', uuid_STAY_ID
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-encounter'
            )
        ) 
        , 'identifier', jsonb_build_array(jsonb_build_object(
                'value', ed_STAY_ID
                , 'system', 'http://mimic.mit.edu/fhir/mimic/identifier/encounter-ed'
                , 'use', 'usual'
                , 'assigner', jsonb_build_object('reference', 'Organization/' || uuid_ORG)
        ))	
        , 'status', 'finished' -- ALL encounters assumed finished
        , 'class', jsonb_build_object(
            'system', 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
            , 'code', 'EMER'
            , 'display', 'emergency'
        )
        , 'type', 
            jsonb_build_array(jsonb_build_object(
                'coding', jsonb_build_array(json_build_object(
                    'system', 'http://snomed.info/sct'
                    , 'code', '308335008'
                    , 'display', 'Patient encounter procedure'
                ))
            ))  
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'period', jsonb_build_object(
            'start', ed_INTIME
            , 'end', ed_OUTTIME
        )
        , 'partOf', 
            CASE WHEN uuid_HADM_ID IS NOT NULL THEN
                jsonb_build_object('reference', 'Encounter/' || uuid_HADM_ID)  
            ELSE NULL END
        , 'hospitalization', jsonb_build_object(
            'admitSource', 
                CASE WHEN ed_ARRIVAL_TRANSPORT IS NOT NULL
                THEN jsonb_build_object(
                    'coding',  jsonb_build_array(jsonb_build_object(
                        'system', 'http://mimic.mit.edu/fhir/mimic/CodeSystem/mimic-admit-source'
                        , 'code', ed_ARRIVAL_TRANSPORT
                    ))                
                ) ELSE NULL END
        , 'dischargeDisposition', 
            CASE WHEN ed_DISPOSITION IS NOT NULL
                THEN jsonb_build_object(
                    'coding',  jsonb_build_array(jsonb_build_object(
                        'system', 'http://mimic.mit.edu/fhir/mimic/CodeSystem/mimic-discharge-disposition'
                        , 'code', ed_DISPOSITION
                    ))                
                ) ELSE NULL END
        )   
        , 'serviceProvider', jsonb_build_object('reference', 'Organization/' || uuid_ORG)	 		
    )) AS fhir
FROM 
    fhir_encounter_ed;
