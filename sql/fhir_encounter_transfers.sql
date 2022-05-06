-- Purpose: Generate a encounters for transfers and link to primary encounter
-- Method:  link transfers to main encounter by partOf reference

-- Questions
-- Do we keep all tranfer types (admit, discharge, ED, transfers). I think ED should be dropped here

DROP TABLE IF EXISTS mimic_fhir.encounter_transfers;
CREATE TABLE mimic_fhir.encounter_transfers(
    id              uuid PRIMARY KEY,
    patient_id      uuid NOT NULL,
    fhir            jsonb NOT NULL 
);

WITH fhir_encounter_transfers AS (
    SELECT 
        transfer_id AS transfers_TRANSFER_ID
        , CAST(intime AS TIMESTAMPTZ) AS transfers_INTIME
        , CAST(outtime AS TIMESTAMPTZ) AS transfers_OUTTIME   
        , careunit AS transfers_CAREUNIT
    
        -- UUID identifiers
        , uuid_generate_v5(ns_patient.uuid, CAST(tfr.subject_id AS TEXT)) AS subject_id_UUID
        , uuid_generate_v5(ns_encounter.uuid, CAST(hadm_id AS TEXT)) AS hadm_id_UUID
        , uuid_generate_v5(ns_transfers.uuid, CAST(transfer_id AS TEXT)) AS transfers_UUID
        , uuid_generate_v5(ns_organization.uuid, careunit) AS careunit_UUID
    FROM 
        mimic_core.transfers tfr
        INNER JOIN fhir_etl.subjects sub
            ON tfr.subject_id = sub.subject_id
        LEFT JOIN fhir_etl.uuid_namespace ns_encounter
            ON ns_encounter.name = 'Encounter'
        LEFT JOIN fhir_etl.uuid_namespace ns_patient
            ON ns_patient.name = 'Patient'
        LEFT JOIN fhir_etl.uuid_namespace ns_transfers
            ON ns_transfers.name = 'EncounterTransfers'
        LEFT JOIN fhir_etl.uuid_namespace ns_organization
            ON ns_organization.name = 'Organization'
    WHERE eventtype != 'ED' -- just pull inpatient encounters
)
INSERT INTO mimic_fhir.encounter_transfers 
SELECT 
    transfers_UUID AS id
    , subject_id_UUID AS patient_id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Encounter'
        , 'id', transfers_UUID
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://fhir.mimic.mit.edu/StructureDefinition/mimic-encounter-transfers'
            )
        ) 
         , 'identifier', jsonb_build_array(jsonb_build_object(
                'value', transfers_TRANSFER_ID
                , 'system', 'http://fhir.mimic.mit.edu/identifier/encounter-transfers'
        ))  
        , 'status', 'finished' -- ALL transfers encounters assumed finished
        , 'class', jsonb_build_object(
            'code', 'IMP'
            , 'display', 'inpatient patient'
            , 'system', 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
        )
        , 'type', jsonb_build_array(jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'code', 'transfer encounter'
                , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/transfer-type'
            ))
        ))
        , 'serviceType', CASE WHEN transfers_CAREUNIT IS NOT NULL THEN
            jsonb_build_object(
                'coding', jsonb_build_array(jsonb_build_object(
                    'code', transfers_CAREUNIT
                    , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/careunit'
                ))
            )
        ELSE NULL END
        , 'period', jsonb_build_object(
            'start', transfers_INTIME
            , 'end', transfers_OUTTIME        
        )
        , 'subject',  jsonb_build_object('reference', 'Patient/' || subject_id_UUID)
        , 'serviceProvider', 
            CASE WHEN careunit_UUID IS NOT NULL 
                THEN jsonb_build_object('reference', 'Organization/' || careunit_UUID)
            ELSE NULL END
        , 'partOf', jsonb_build_object('reference', 'Encounter/' || hadm_id_UUID)         
    )) AS fhir    
FROM fhir_encounter_transfers 
