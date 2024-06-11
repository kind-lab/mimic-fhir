-- Purpose: Generate a FHIR MedicationDispense resource for each row in pharmacy 
--          Add additional information from emar/emar_detail if available
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit


SELECT fhir_etl.fn_create_table_patient_dependent('medication_dispense');


WITH distinct_prescriptions AS (
    SELECT DISTINCT pharmacy_id
    FROM mimiciv_hosp.prescriptions 
)
-- Collect all pharmacy_id in pharmacy. 
-- There are some pharmacy_id in prescriptions that will not have a related pharmacy_id in pharmacy
, fhir_medication_dispense AS (
    SELECT 
        CAST(ph.pharmacy_id AS TEXT) AS ph_PHARMACY_ID
        
        -- dosage information
        , ph.route AS ph_ROUTE
        , ph.frequency AS ph_FREQUENCY
        , ph.disp_sched AS ph_DISP_SCHED
        , CASE WHEN ph.one_hr_max ~ '^[0-9\.]+$' THEN 
            CAST(ph.one_hr_max AS DECIMAL) 
        ELSE NULL END AS ph_ONE_HR_MAX
        , ph.doses_per_24_hrs AS ph_DOSES_PER_24_HRS
        , ph.duration AS ph_DURATION
        , medu.fhir_unit AS medu_FHIR_UNIT
        , ph.dispensation AS ph_DISPENSATION
        , ph.fill_quantity AS ph_FILL_QUANTITY
        -- assume the ph.fill_quantity is [#]<decima-number>[<unit>]. The unit can be quoted. Valid units are ml, bottle, btl, g, lb
        -- anything else will produce NULL ph_FILL_QUANTITY_VALUE.
        -- Quantities without unit will produce NULL ph_FILL_QUANTITY_UNIT  (notice the difference in the reg. expressions)
        , (regexp_match(ph.fill_quantity, '^\s*#?(\d+(\.\d+)?)\s*''*(|ml|bottle|btl|g|lb)''*\s*$','i'))[1]::NUMERIC AS ph_FILL_QUANTITY_VALUE
        , replace(lower((regexp_match(ph.fill_quantity, '^\s*#?(\d+(\.\d+)?)\s*''*(ml|bottle|btl|g|lb)''*\s*$','i'))[3]), 'btl', 'bottle') AS ph_FILL_QUANTITY_UNIT
        , TRIM(REGEXP_REPLACE(ph.medication, '\s+', ' ', 'g')) AS ph_MEDICATION
        , CASE WHEN ph.duration IS NULL 
                AND ph.frequency IS NULL 
                AND ph.one_hr_max IS NULL 
                AND ph.route IS NULL 
        THEN FALSE ELSE TRUE END AS dosageInstructionFlag
        
        -- reference uuids
        , uuid_generate_v5(ns_medication_dispense.uuid, CAST(ph.pharmacy_id AS TEXT)) AS uuid_MEDICATION_DISPENSE
        
        -- Some pharmacy_ids exist in pharmacy but not in prescriptions, so no medication request would have been created
        , CASE WHEN pr.pharmacy_id IS NOT NULL THEN
            uuid_generate_v5(ns_medication_request.uuid, CAST(ph.pharmacy_id AS TEXT)) 
        ELSE NULL END AS uuid_MEDICATION_REQUEST 
        , uuid_generate_v5(ns_patient.uuid, CAST(ph.subject_id AS TEXT)) AS uuid_SUBJECT_ID
        , uuid_generate_v5(ns_encounter.uuid, CAST(ph.hadm_id AS TEXT)) AS uuid_HADM_ID
    FROM 
        mimiciv_hosp.pharmacy ph 
        LEFT JOIN distinct_prescriptions pr
            ON ph.pharmacy_id = pr.pharmacy_id
            
        -- UUID namespaces
        LEFT JOIN fhir_etl.uuid_namespace ns_encounter
            ON ns_encounter.name = 'Encounter'
        LEFT JOIN fhir_etl.uuid_namespace ns_patient
            ON ns_patient.name = 'Patient'
        LEFT JOIN fhir_etl.uuid_namespace ns_medication_request
            ON ns_medication_request.name = 'MedicationRequest'
        LEFT JOIN fhir_etl.uuid_namespace ns_medication_dispense
            ON ns_medication_dispense.name = 'MedicationDispense'
            
        -- ValueSet MAPPING 
        LEFT JOIN fhir_etl.map_med_duration_unit medu 
            ON ph.duration_interval = medu.mimic_unit 
    
    -- only create medication dispense if medication is specified
    WHERE 
        ph.medication IS NOT NULL
) 

INSERT INTO mimic_fhir.medication_dispense
SELECT
    uuid_MEDICATION_DISPENSE AS id
    , uuid_SUBJECT_ID AS patient_id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'MedicationDispense'
        , 'id', uuid_MEDICATION_DISPENSE
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://mimic.mit.edu/fhir/mimic/StructureDefinition/mimic-medication-dispense'
            )
         ) 
        , 'identifier', jsonb_build_array(jsonb_build_object(
              'value', ph_PHARMACY_ID
              , 'system', 'http://mimic.mit.edu/fhir/mimic/identifier/medication-dispense'
        ))    
        , 'status', 'completed' -- assumed all complete dispense in mimic
        , 'medicationCodeableConcept', jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'code', ph_MEDICATION
                , 'system', 'http://mimic.mit.edu/fhir/mimic/CodeSystem/mimic-medication-name'
            ))
        )
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'context', 
            CASE WHEN uuid_HADM_ID IS NOT NULL
              THEN jsonb_build_object('reference', 'Encounter/' || uuid_HADM_ID) 
              ELSE NULL
            END
        , 'authorizingPrescription', 
            CASE WHEN uuid_MEDICATION_REQUEST IS NOT NULL THEN
                jsonb_build_array(jsonb_build_object(
                    'reference', 'MedicationRequest/' || uuid_MEDICATION_REQUEST
                ))  
            ELSE NULL END
        , 'quantity', 
            CASE WHEN ph_FILL_QUANTITY_VALUE IS NOT NULL THEN
                jsonb_build_object(
                    'value', ph_FILL_QUANTITY_VALUE
                    , 'unit', ph_FILL_QUANTITY_UNIT
                ) 
            ELSE NULL END 
        , 'dosageInstruction', CASE WHEN dosageInstructionFlag THEN ARRAY[jsonb_build_object(
            'route', CASE WHEN ph_ROUTE IS NOT NULL THEN 
               jsonb_build_object(
                    'coding', jsonb_build_array(jsonb_build_object(
                        'system', 'http://mimic.mit.edu/fhir/mimic/CodeSystem/mimic-medication-route'  
                        , 'code', ph_ROUTE
                    ))
                )
                ELSE NULL END           
            , 'timing', CASE WHEN ph_FREQUENCY IS NOT NULL AND ph_DURATION IS NOT NULL THEN jsonb_build_object(
                'code', CASE WHEN ph_FREQUENCY IS NOT NULL THEN 
                    jsonb_build_object(
                        'coding', jsonb_build_array(jsonb_build_object(
                            'code', ph_FREQUENCY
                            , 'system', 'http://mimic.mit.edu/fhir/mimic/CodeSystem/mimic-medication-frequency'
                        ))
                    )
                    ELSE NULL END
                , 'repeat', CASE WHEN ph_DURATION IS NOT NULL AND medu_FHIR_UNIT IS NOT NULL THEN jsonb_build_object(
                    'duration', ph_DURATION
                    , 'durationUnit', medu_FHIR_UNIT                                                
                ) ELSE NULL END
                
            ) ELSE NULL END
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
            
        )] ELSE NULL END
    )) AS fhir  
FROM 
    fhir_medication_dispense
