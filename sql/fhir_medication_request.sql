-- Purpose: Generate a FHIR MedicationRequest resource for each row in the prescriptions/pharmacy tables.
--          Add in the prescription requests that are not found in pharmacy too.
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit

DROP TABLE IF EXISTS mimic_fhir.medication_request;
CREATE TABLE mimic_fhir.medication_request(
    id             uuid PRIMARY KEY,
    patient_id     uuid NOT NULL,
    fhir           jsonb NOT NULL 
);


-- Create medicationRequest resources from the prescription table 
-- Pull information from pharmacy to supplement prescriptions table


WITH prescript_request AS (
    SELECT 
        pr.pharmacy_id
        , MAX(pr.route) AS route -- ALL routes across drugs IN a prescription ARE the same
        , MAX(pr.starttime) AS starttime 
        , MAX(pr.stoptime) AS stoptime
        , MAX(pr.hadm_id) AS hadm_id
        , MAX(pr.subject_id) AS subject_id
        
        -- Dosage information
        , MAX(dose_val_rx) AS dose_val_rx        
        , MAX(dose_unit_rx) AS dose_unit_rx        
        , MAX(form_val_disp) AS form_val_disp    
        , MAX(form_unit_disp) AS form_unit_disp
        , MAX(prod_strength) AS prod_strength
        , STRING_AGG( 
             drug
            || CASE WHEN (formulary_drug_cd IS NOT NULL) AND (formulary_drug_cd != '') 
                    THEN '--' || formulary_drug_cd ELSE '' END    
            || CASE WHEN (ndc IS NOT NULL) AND (ndc !='0') AND (ndc != '') 
                    THEN '--' || ndc ELSE '' END            
            , '_' ORDER BY pr.drug_type DESC, pr.drug ASC
        ) AS drug_code  
    FROM 
        mimic_hosp.prescriptions pr
    GROUP BY pr.pharmacy_id 
), fhir_medication_request AS (
	SELECT
  		CAST(pr.pharmacy_id AS TEXT) AS pr_PHARMACY_ID
  		, COALESCE(stat.fhir_status, 'unknown') AS stat_FHIR_STATUS -- NULL IF ONLY prescription link (missing pharmacy link). Coalesce AS unknown
  		, TRIM(COALESCE(ph.route, pr.route)) AS ph_ROUTE
  		, CAST(COALESCE(ph.starttime, pr.starttime) AS TIMESTAMPTZ) AS ph_STARTTIME
  		, CAST(COALESCE(ph.stoptime, pr.stoptime) AS TIMESTAMPTZ) AS ph_STOPTIME  	
  		
  		-- dosage information. Only populated for pharmacy, so any prescriptions 
  		-- without a pharmacy entry will just have NULL values (could Coalesce for clarity)
  		, TRIM(REGEXP_REPLACE(ph.frequency, '\s+', ' ', 'g')) AS ph_FREQUENCY -- trim FOR whitespace rules IN FHIR
  		--, ph.disp_sched AS ph_DISP_SCHED -- CONVERT TO HH:MM:SS format AND split BY comma
  		, CASE WHEN ph.one_hr_max ~ '^[0-9\.]+$'  THEN 
  		    CAST(ph.one_hr_max AS DECIMAL) 
  		ELSE NULL END AS ph_ONE_HR_MAX
  		, ph.duration AS ph_DURATION 
        , medu.fhir_unit AS medu_FHIR_UNIT
        , CAST(ph.entertime AS TIMESTAMPTZ) AS ph_ENTERTIME
        
        -- dosage information from prescriptions
        , CASE WHEN pr.dose_val_rx ~ '^[0-9\.]+$' THEN 
             CAST(pr.dose_val_rx AS DECIMAL)
        ELSE NULL END AS pr_DOSE_VAL_RX 
        , TRIM(pr.dose_unit_rx) AS pr_DOSE_UNIT_RX
        , pr.form_val_disp AS pr_FORM_VAL_DISP
        , pr.form_unit_disp AS pr_FORM_UNIT_DISP
        , pr.prod_strength AS pr_PROD_STRENGTH
        , CASE WHEN pr.prod_strength IS NULL 
                AND ph.duration IS NULL 
                AND ph.frequency IS NULL 
                AND pr.dose_val_rx IS NULL
                AND ph.one_hr_max IS NULL 
                AND COALESCE(ph.route, pr.route) IS NULL 
        THEN FALSE ELSE TRUE END AS dosageInstructionFlag

            
  		-- reference uuids
  		, uuid_generate_v5(ns_medication_request.uuid, CAST(pr.pharmacy_id AS TEXT)) AS uuid_MEDICATION_REQUEST 
  		, uuid_generate_v5(ns_medication.uuid, drug_code) AS uuid_MEDICATION 
  		, uuid_generate_v5(ns_patient.uuid, CAST(pr.subject_id AS TEXT)) AS uuid_SUBJECT_ID
  		, uuid_generate_v5(ns_encounter.uuid, CAST(pr.hadm_id AS TEXT)) AS uuid_HADM_ID
  	FROM
  	    prescript_request pr
  	    LEFT JOIN mimic_hosp.pharmacy ph
            ON pr.pharmacy_id = ph.pharmacy_id  
  		LEFT JOIN fhir_etl.uuid_namespace ns_encounter
  			ON ns_encounter.name = 'Encounter'
  		LEFT JOIN fhir_etl.uuid_namespace ns_patient
  			ON ns_patient.name = 'Patient'
  		LEFT JOIN fhir_etl.uuid_namespace ns_medication
  			ON ns_medication.name = 'MedicationPrescriptions'
  		LEFT JOIN fhir_etl.uuid_namespace ns_medication_request
  			ON ns_medication_request.name = 'MedicationRequest'
  		
  		-- ValueSet mapping	
  		LEFT JOIN fhir_etl.map_medreq_status stat
  		    ON ph.status = stat.mimic_status   
  		LEFT JOIN fhir_etl.map_med_duration_unit medu 
  		    ON ph.duration_interval = medu.mimic_unit 
) 

INSERT INTO mimic_fhir.medication_request
SELECT 
	uuid_MEDICATION_REQUEST AS id
	, uuid_SUBJECT_ID AS patient_id
	, jsonb_strip_nulls(jsonb_build_object(
    	'resourceType', 'MedicationRequest'
        , 'id', uuid_MEDICATION_REQUEST
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://fhir.mimic.mit.edu/StructureDefinition/mimic-medication-request'
            )
         ) 
      	, 'identifier', jsonb_build_array(jsonb_build_object(
            'value', pr_PHARMACY_ID
            , 'system', 'http://fhir.mimic.mit.edu/identifier/medication-request-phid'
        ))	
        , 'status', stat_FHIR_STATUS
      	, 'intent', 'order'
      	, 'medicationReference', jsonb_build_object('reference', 'Medication/' || uuid_MEDICATION)
      	, 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
      	, 'encounter', 
      		CASE WHEN uuid_HADM_ID IS NOT NULL
      		  THEN jsonb_build_object('reference', 'Encounter/' || uuid_HADM_ID) 
      		  ELSE NULL
      		END
      	, 'authoredOn', ph_ENTERTIME
        , 'dosageInstruction', CASE WHEN dosageInstructionFlag THEN ARRAY[jsonb_build_object(
            'text', pr_PROD_STRENGTH
        	, 'route', CASE WHEN ph_ROUTE IS NOT NULL THEN 
        	   jsonb_build_object(
                    'coding', jsonb_build_array(jsonb_build_object(
                        'system', 'http://fhir.mimic.mit.edu/CodeSystem/mimic-medication-route'  
                        , 'code', ph_ROUTE
                    ))
                )
                ELSE NULL END
            
            -- dose_val_rx has ranges and free text, need to clean up so passing numeric values to validator
            ,'doseAndRate', CASE WHEN pr_DOSE_VAL_RX IS NOT NULL THEN jsonb_build_array(jsonb_build_object(
                'doseQuantity', jsonb_build_object(
                    'value', pr_DOSE_VAL_RX
                    , 'unit', pr_DOSE_UNIT_RX
                    , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/mimic-units'
                    , 'code', pr_DOSE_UNIT_RX
                )
            )) ELSE NULL END 
            , 'timing', CASE WHEN ph_FREQUENCY IS NOT NULL AND ph_DURATION IS NOT NULL THEN jsonb_build_object(
                'code', CASE WHEN ph_FREQUENCY IS NOT NULL THEN 
                    jsonb_build_object(
                        'coding', jsonb_build_array(jsonb_build_object(
                            'code', ph_FREQUENCY
                            , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/mimic-medication-frequency'
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
        , 'dispenseRequest', CASE WHEN ph_STARTTIME IS NOT NULL AND (ph_STARTTIME <= ph_STOPTIME) THEN jsonb_build_object(
        	 'validityPeriod', jsonb_build_object(
               	'start', ph_STARTTIME
               	, 'end', ph_STOPTIME
              )
        ) ELSE NULL END     
    )) AS fhir  
FROM
	fhir_medication_request;
	
	
	
	
-- Create medicationRequest resources poe table for emar events without pharmacy_id
-- And for now just grab emar events with non-null medication valuesjsonb_build_object(

-- get unique poe_id that show up in emar, without pharmacy_id and with medication or poe iv order
WITH prescriptions AS (
    SELECT DISTINCT pharmacy_id FROM mimic_hosp.prescriptions 
), poe_medreq AS (
    SELECT DISTINCT 
        em.poe_id
        , em.medication
        , poe.order_type 
    FROM 
        mimic_hosp.emar em
        LEFT JOIN prescriptions pr
            ON em.pharmacy_id = pr.pharmacy_id
        LEFT JOIN mimic_hosp.poe
            ON em.poe_id = poe.poe_id
    WHERE 
        pr.pharmacy_id IS NULL
        AND (em.medication IS NOT NULL 
        OR poe.order_type IN ('TPN', 'IV therapy'))
), fhir_poe_medication_request AS (
    SELECT
        poe.poe_id AS poe_POE_ID
        , CAST(poe.ordertime AS TIMESTAMPTZ) AS poe_ORDERTIME 
         , COALESCE(stat.fhir_status, 'unknown') AS stat_FHIR_STATUS
    
        -- reference uuids
        , uuid_generate_v5(ns_medication_request.uuid, poe.poe_id) AS uuid_MEDICATION_REQUEST 
        , CASE 
            WHEN pm.medication IS NOT NULL THEN
                TRIM(REGEXP_REPLACE(pm.medication, '\s+', ' ', 'g')) 
            WHEN pm.order_type IN ('TPN', 'IV therapy') THEN
                pm.order_type
        END AS pm_MEDICATION 
        
        , CASE 
            WHEN pm.medication IS NOT NULL THEN
                'http://fhir.mimic.mit.edu/CodeSystem/mimic-medication-name'
            WHEN pm.order_type IN ('TPN', 'IV therapy') THEN
                'http://fhir.mimic.mit.edu/CodeSystem/mimic-medication-poe-iv'
        END AS pm_MEDICATION_SYSTEM
        
        , uuid_generate_v5(ns_patient.uuid, CAST(poe.subject_id AS TEXT)) AS uuid_SUBJECT_ID
        , uuid_generate_v5(ns_encounter.uuid, CAST(poe.hadm_id AS TEXT)) AS uuid_HADM_ID
    FROM
        poe_medreq pm
        INNER JOIN mimic_hosp.poe poe
            ON pm.poe_id = poe.poe_id
        
        -- uuid namespaces
        LEFT JOIN fhir_etl.uuid_namespace ns_encounter
            ON ns_encounter.name = 'Encounter'
        LEFT JOIN fhir_etl.uuid_namespace ns_patient
            ON ns_patient.name = 'Patient'
        LEFT JOIN fhir_etl.uuid_namespace ns_medication_name
            ON ns_medication_name.name = 'MedicationName'
        LEFT JOIN fhir_etl.uuid_namespace ns_medication_poe
            ON ns_medication_poe.name = 'MedicationPoeIv'
        LEFT JOIN fhir_etl.uuid_namespace ns_medication_request
            ON ns_medication_request.name = 'MedicationRequest'
        
        --status mapping
        LEFT JOIN fhir_etl.map_medreq_status stat
            ON poe.order_status = stat.mimic_status   
    WHERE 
        poe.order_type IN ('IV therapy', 'TPN')
        OR pm.medication IS NOT NULL 
)
INSERT INTO mimic_fhir.medication_request
SELECT 
    uuid_MEDICATION_REQUEST AS id
    , uuid_SUBJECT_ID AS patient_id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'MedicationRequest'
        , 'id', uuid_MEDICATION_REQUEST
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://fhir.mimic.mit.edu/StructureDefinition/mimic-medication-request'
            )
         ) 
        , 'identifier', jsonb_build_array(jsonb_build_object(
            'value', poe_POE_ID
            , 'system', 'http://fhir.mimic.mit.edu/identifier/medication-request-poe'
        )) 
        , 'status', stat_FHIR_STATUS
        , 'intent', 'order'
        , 'medicationCodeableConcept', jsonb_build_array(jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'code', pm_MEDICATION
                , 'system', pm_MEDICATION_SYSTEM
            ))
        ))
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'encounter', 
            CASE WHEN uuid_HADM_ID IS NOT NULL
              THEN jsonb_build_object('reference', 'Encounter/' || uuid_HADM_ID) 
              ELSE NULL
            END
        , 'authoredOn', poe_ORDERTIME 

    )) AS fhir  
FROM
    fhir_poe_medication_request;
