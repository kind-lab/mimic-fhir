-- Purpose: Generate a FHIR Encounter reosurce for each row in icustays
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit

DROP TABLE IF EXISTS mimic_fhir.encounter_icu;
CREATE TABLE mimic_fhir.encounter_icu(
    id          uuid PRIMARY KEY,
    patient_id  uuid NOT NULL,
    fhir        jsonb NOT NULL 
);

WITH transfer_location AS (
    SELECT 
        stay_id 
        , min(tfr_first.intime) AS first_intime
        , max(tfr_first.outtime) AS first_outtime
        , min(tfr_last.intime) AS last_intime
        , max(tfr_last.outtime) AS last_outtime
        , min(icu.first_careunit) AS first_careunit 
        , min(icu.last_careunit) AS last_careunit
    FROM 
        mimic_icu.icustays icu
        LEFT JOIN mimic_hosp.transfers tfr_first
            ON icu.hadm_id = tfr_first.hadm_id 
            AND icu.first_careunit = tfr_first.careunit 
            AND tfr_first.intime >= icu.intime
            AND tfr_first.outtime <= icu.outtime 
        LEFT JOIN mimic_hosp.transfers tfr_last
            ON icu.hadm_id = tfr_last.hadm_id 
            AND icu.last_careunit = tfr_last.careunit 
            AND tfr_last.intime >=  icu.intime
            AND tfr_last.outtime <= icu.outtime 
    GROUP BY icu.stay_id
), fhir_encounter_icu AS (
    SELECT 
        CAST(icu.stay_id AS TEXT) AS icu_STAY_ID
        , CAST(icu.intime AS TIMESTAMPTZ) AS icu_INTIME
        , CAST(icu.outtime AS TIMESTAMPTZ) AS icu_OUTTIME
        , icu.los AS icu_LOS  		
        
        -- careunit location and timing
        , uuid_generate_v5(ns_location.uuid, icu.first_careunit) AS uuid_FIRST_CAREUNIT
        , uuid_generate_v5(ns_location.uuid, icu.last_careunit) AS uuid_LAST_CAREUNIT
        , CAST(tfr.first_intime AS TIMESTAMPTZ) AS tfr_FIRST_INTIME
        , CAST(tfr.first_outtime AS TIMESTAMPTZ) AS tfr_FIRST_OUTTIME
        , CAST(tfr.last_intime AS TIMESTAMPTZ) AS tfr_LAST_INTIME
        , CAST(tfr.last_outtime AS TIMESTAMPTZ) AS tfr_LAST_OUTTIME
  	
        -- reference uuids
        , uuid_generate_v5(ns_encounter_icu.uuid, CAST(icu.stay_id AS TEXT)) AS uuid_STAY_ID
        , uuid_generate_v5(ns_encounter.uuid, CAST(icu.hadm_id AS TEXT)) AS uuid_HADM_ID
        , uuid_generate_v5(ns_patient.uuid, CAST(icu.subject_id AS TEXT)) AS uuid_SUBJECT_ID
        
    FROM 
        mimic_icu.icustays icu        
        -- join transfers to get timing in each careunit
        LEFT JOIN transfer_location tfr
            ON icu.stay_id = tfr.stay_id
            
        -- uuid namespaces    
        LEFT JOIN fhir_etl.uuid_namespace ns_encounter	
            ON ns_encounter.name = 'Encounter'
        LEFT JOIN fhir_etl.uuid_namespace ns_patient	
            ON ns_patient.name = 'Patient'
        LEFT JOIN fhir_etl.uuid_namespace ns_encounter_icu
            ON ns_encounter_icu.name = 'EncounterICU'
        LEFT JOIN fhir_etl.uuid_namespace ns_location
            ON ns_location.name = 'Location'
)

INSERT INTO mimic_fhir.encounter_icu
SELECT  
    uuid_STAY_ID as id
    , uuid_SUBJECT_ID AS patient_id 
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Encounter'
        , 'id', uuid_STAY_ID
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://mimic.mit.edu/fhir/StructureDefinition/mimic-encounter'
            )
        ) 
        , 'identifier', jsonb_build_array(jsonb_build_object(
            'value', icu_STAY_ID
            , 'system', 'http://mimic.mit.edu/fhir/identifier/encounter-icu'	
        ))	
        , 'status', 'finished' -- ALL encounters considered finished
        -- All ICU encounters in the class ACUTE
        , 'class', jsonb_build_object(
            'system', 'http://terminology.hl7.org/CodeSystem/v3-ActCode'
            , 'code', 'ACUTE'
        )
           
        -- Fixed type to in-person encounter, location holds careunit information  
        , 'type', jsonb_build_array(jsonb_build_object(
            'coding', jsonb_build_array(json_build_object(
                'system', 'http://snomed.info/sct'
                , 'code', '308335008'
                , 'display', 'Patient encounter procedure'
            ))
        ))
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'period', jsonb_build_object(
            'start', icu_INTIME
            , 'end', icu_OUTTIME
        )
        , 'location', ARRAY_REMOVE(ARRAY[
            jsonb_build_object(
                'location', jsonb_build_object('reference', 'Location/' || uuid_FIRST_CAREUNIT)
                , 'period', jsonb_build_object(
                    'start', tfr_FIRST_INTIME
                    , 'end', tfr_FIRST_OUTTIME
                )
            )
            , CASE WHEN uuid_FIRST_CAREUNIT != uuid_LAST_CAREUNIT THEN
                jsonb_build_object(
                    'location', jsonb_build_object('reference', 'Location/' || uuid_LAST_CAREUNIT)
                    , 'period', jsonb_build_object(
                        'start', tfr_LAST_INTIME
                        , 'end', tfr_LAST_OUTTIME
                    )
                )
            ELSE NULL END            
        ], NULL)
        , 'partOf', jsonb_build_object('reference', 'Encounter/' || uuid_HADM_ID)
    )) as fhir
FROM 
    fhir_encounter_icu
