-- Purpose: Generate a FHIR Procedure resource for each procedures_icd row
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit

DROP TABLE IF EXISTS mimic_fhir.procedure;
CREATE TABLE mimic_fhir.procedure(
	id 		uuid PRIMARY KEY,
	patient_id  uuid NOT NULL,
  	fhir 	jsonb NOT NULL 
);

WITH fhir_procedure AS (
	SELECT
  		proc.hadm_id || '-' || proc.seq_num || '-' || proc.icd_code AS proc_IDENTIFIER 
  		, proc.icd_code AS proc_ICD_CODE
  		, CAST(proc.chartdate AS TIMESTAMPTZ) AS proc_CHARTDATE
  		, proc.icd_version AS proc_ICD_VERSION
  
  		-- reference uuids
  		, uuid_generate_v5(ns_procedure.uuid, proc.hadm_id || '-' || proc.seq_num || '-' || proc.icd_code) AS uuid_PROCEDURE_ID
  		, uuid_generate_v5(ns_patient.uuid, CAST(proc.subject_id AS TEXT)) AS uuid_SUBJECT_ID
  		, uuid_generate_v5(ns_encounter.uuid, CAST(proc.hadm_id AS TEXT)) AS uuid_HADM_ID
  	FROM
  		mimic_hosp.procedures_icd proc
  		INNER JOIN fhir_etl.subjects sub
  			ON proc.subject_id = sub.subject_id 
  		LEFT JOIN fhir_etl.uuid_namespace ns_encounter
  			ON ns_encounter.name = 'Encounter'
  		LEFT JOIN fhir_etl.uuid_namespace ns_patient
  			ON ns_patient.name = 'Patient'
  		LEFT JOIN fhir_etl.uuid_namespace ns_procedure
  			ON ns_procedure.name = 'Procedure'
)

INSERT INTO mimic_fhir.procedure
SELECT 
	uuid_PROCEDURE_ID AS id
	, uuid_SUBJECT_ID AS patient_id 
	, jsonb_strip_nulls(jsonb_build_object(
    	'resourceType', 'Procedure'
        , 'id', uuid_PROCEDURE_ID
        , 'meta', jsonb_build_object(
        	'profile', jsonb_build_array(
        		'http://fhir.mimic.mit.edu/StructureDefinition/mimic-procedure'
        	)
        ) 
      	, 'identifier', 
      		jsonb_build_array(
        		jsonb_build_object(
                  'value', proc_IDENTIFIER
                  , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/identifier-procedure'
        		)
      		)		 
        , 'status', 'completed' -- All procedures are considered complete
        
        -- ICD code for procedure event
        , 'code', jsonb_build_object(
          	'coding', jsonb_build_array(jsonb_build_object(
            	'system', CASE WHEN proc_ICD_VERSION = 9 THEN 'http://fhir.mimic.mit.edu/CodeSystem/procedure-icd9' 
            				   ELSE 'http://fhir.mimic.mit.edu/CodeSystem/procedure-icd10'	END
                , 'code', proc_ICD_CODE
            ))
          )
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'encounter', jsonb_build_object('reference', 'Encounter/' || uuid_HADM_ID) 
        , 'performedDateTime', proc_CHARTDATE
    )) AS fhir 
FROM
	fhir_procedure
