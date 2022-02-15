-- Purpose: Generate a FHIR MedicationDispense resource for each row in pharmacy 
--          Add additional information from emar/emar_detail if available
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit


DROP TABLE IF EXISTS mimic_fhir.medication_dispense;
CREATE TABLE mimic_fhir.medication_dispense(
    id      uuid PRIMARY KEY,
    fhir    jsonb NOT NULL 
);


-- Collect all emar evetns associated with pharmacy_id
WITH emar_events AS (
    SELECT 
        emd.pharmacy_id
        , jsonb_agg(
            jsonb_build_object('reference', 'MedicationAdministration/' ||
                uuid_generate_v5(ns_medadmin.uuid, emd.emar_id || 
                                            '-' || emd.emar_seq || 
                                            '-' || emd.parent_field_ordinal
                )
            )
        ) AS uuid_MEDADMIN
    FROM 
        mimic_hosp.emar_detail emd
        INNER JOIN fhir_etl.subjects sub
            ON emd.subject_id = sub.subject_id
        LEFT JOIN fhir_etl.uuid_namespace ns_medadmin 
            ON ns_medadmin.name = 'MedicationAdministration'    
    WHERE 
        emd.parent_field_ordinal IS NOT NULL
    GROUP BY 
        emd.pharmacy_id 
), fhir_medication_request AS (
    SELECT 
        CAST(ph.pharmacy_id AS TEXT) AS ph_PHARMACY_ID
        
        -- dosage information
        , ph.route AS ph_ROUTE
        , ph.frequency AS ph_FREQUENCY
        , ph.disp_sched AS ph_DISP_SCHED
        , ph.one_hr_max AS ph_ONE_HR_MAX
        , ph.doses_per_24_hrs AS ph_DOSES_PER_24_HRS
        , ph.duration AS ph_DURATION
        , medu.fhir_unit AS medu_FHIR_UNIT
        , ph.dispensation AS ph_DISPENSATION
        , ph.fill_quantity AS ph_FILL_QUANTITY
        
        -- reference uuids
        , uuid_generate_v5(ns_medication_dispense.uuid, CAST(ph.pharmacy_id AS TEXT)) AS uuid_MEDICATION_DISPENSE
        , em.uuid_MEDADMIN AS uuid_MEDADMIN
        , uuid_generate_v5(ns_medication_request.uuid, CAST(ph.pharmacy_id AS TEXT)) AS uuid_MEDICATION_REQUEST 
        , uuid_generate_v5(ns_medication.uuid, ph.medication) AS uuid_MEDICATION 
        , uuid_generate_v5(ns_patient.uuid, CAST(ph.subject_id AS TEXT)) AS uuid_SUBJECT_ID
        , uuid_generate_v5(ns_encounter.uuid, CAST(ph.hadm_id AS TEXT)) AS uuid_HADM_ID
    FROM 
        mimic_hosp.pharmacy ph 
        INNER JOIN fhir_etl.subjects sub 
            ON ph.subject_id = sub.subject_id 
        LEFT JOIN emar_events em
            ON ph.pharmacy_id = em.pharmacy_id
        
        -- UUID namespaces
        LEFT JOIN fhir_etl.uuid_namespace ns_encounter
            ON ns_encounter.name = 'Encounter'
        LEFT JOIN fhir_etl.uuid_namespace ns_patient
            ON ns_patient.name = 'Patient'
        LEFT JOIN fhir_etl.uuid_namespace ns_medication
            ON ns_medication.name = 'Medication'
        LEFT JOIN fhir_etl.uuid_namespace ns_medadmin
            ON ns_medadmin.name = 'MedicationDAdministration'
        LEFT JOIN fhir_etl.uuid_namespace ns_medication_request
            ON ns_medication_request.name = 'MedicationRequest'
        LEFT JOIN fhir_etl.uuid_namespace ns_medication_dispense
            ON ns_medication_dispense.name = 'MedicationDispense'
            
        -- ValueSet MAPPING 
        LEFT JOIN fhir_etl.map_med_duration_unit medu 
            ON ph.duration_interval = medu.mimic_unit 
    
    -- only create medication dispense if medication is specified
    WHERE ph.medication IS NOT NULL
) 

INSERT INTO mimic_fhir.medication_dispense
SELECT
    uuid_MEDICATION_DISPENSE AS id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'MedicationDispense'
        , 'id', uuid_MEDICATION_REQUEST
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://fhir.mimic.mit.edu/StructureDefinition/mimic-medication-dispense'
            )
         ) 
        , 'identifier', jsonb_build_array(jsonb_build_object(
              'value', ph_PHARMACY_ID
              , 'system', 'http://fhir.mimic.mit.edu/identifier/medication-dispense'
        ))    
        , 'status', 'completed' -- assumed all complete dispense in mimic
        , 'medicationReference', jsonb_build_object(
            'reference', 'Medication/' || uuid_MEDICATION
        )
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'context', 
            CASE WHEN uuid_HADM_ID IS NOT NULL
              THEN jsonb_build_object('reference', 'Encounter/' || uuid_HADM_ID) 
              ELSE NULL
            END
        , 'authorizingPrescription', jsonb_build_array(jsonb_build_object(
            'reference', 'MedicationRequest/' || uuid_MEDICATION_REQUEST
        ))  
        , 'quantity', 
            CASE WHEN ph_FILL_QUANTITY IS NOT NULL THEN 
                jsonb_build_object(
                    'value', ph_FILL_QUANTITY
                ) 
            ELSE NULL END 
        , 'dosageInstruction', jsonb_build_array(jsonb_build_object(
            'route', jsonb_build_object(
              'coding', jsonb_build_array(jsonb_build_object(
                  'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-route'  
                  , 'code', ph_ROUTE
              ))
            )
            , 'timing', jsonb_build_object(
                'code', jsonb_build_object(
                    'coding', jsonb_build_array(jsonb_build_object(
                        'code', ph_FREQUENCY
                        , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-frequency'
                    ))
                )
                , 'repeat', CASE WHEN ph_DURATION IS NOT NULL THEN jsonb_build_object(
                    'duration', ph_DURATION
                    , 'durationUnit', jsonb_build_object(
                        'coding', jsonb_build_array(jsonb_build_object(
                            'code', medu_FHIR_UNIT
                            , 'system', 'http://unitsofmeasure.org'
                        ))
                    )
                        
                ) ELSE NULL END
                
            )
            , 'maxDosePerPeriod', CASE WHEN ph_ONE_HR_MAX IS NOT NULL THEN jsonb_build_object(
                'numerator', jsonb_build_object(
                    'value', ph_ONE_HR_MAX
                ) 
                , 'denominator', jsonb_build_object(
                    'value', 1
                    , 'unit', 'h'
                    , 'system', 'http://unitsofmeasure.org'
                )         
            ) ELSE NULL END    
        ))
        , 'partOf', uuid_MEDADMIN
    )) AS fhir  
FROM 
    fhir_medication_request 

