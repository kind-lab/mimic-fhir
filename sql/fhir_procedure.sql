DROP TABLE IF EXISTS mimic_fhir.procedure;
CREATE TABLE mimic_fhir.procedure(
	id 		uuid PRIMARY KEY,
  	fhir 	jsonb NOT NULL 
);

WITH vars as (
	SELECT
  		uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Encounter') as uuid_encounter
  		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Patient') as uuid_patient
 		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Procedure') as uuid_procedure
), fhir_procedure as (
	SELECT
  		proc.hadm_id || '-' || proc.seq_num  as proc_IDENTIFIER 
  		, proc.icd_code as proc_ICD_CODE
  		, proc.chartdate as proc_CHARTDATE
  
  		-- refernce uuids
  		, uuid_generate_v5(uuid_procedure, proc.hadm_id::text || '-' || proc.seq_num::text || '-' || proc.icd_code::text) as uuid_PROCEDURE_ID
  		, uuid_generate_v5(uuid_patient, proc.subject_id::text) as uuid_SUBJECT_ID
  		, uuid_generate_v5(uuid_encounter, proc.hadm_id::text) as uuid_HADM_ID
  	FROM
  		mimic_hosp.procedures_icd proc
  		LEFT JOIN vars ON true
    WHERE 
  		proc.subject_id < 10010000
)

INSERT INTO mimic_fhir.procedure
SELECT 
	uuid_PROCEDURE_ID as id
	, jsonb_strip_nulls(jsonb_build_object(
    	'resourceType', 'Procedure'
        , 'id', uuid_PROCEDURE_ID
      	, 'identifier', 
      		jsonb_build_array(
        		jsonb_build_object(
                  'value', proc_IDENTIFIER
                  , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/identifier-procedure'
        		)
      		)		 
        , 'status', 'completed'
        , 'code', jsonb_build_object(
          	'coding', jsonb_build_array(jsonb_build_object(
            	'system', 'http://fhir.mimic.mit.edu/CodeSystem/procedure-icd9'  
                , 'code', proc_ICD_CODE
            ))
          )
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'encounter', jsonb_build_object('reference', 'Encounter/' || uuid_HADM_ID) 
        , 'performedDateTime', proc_CHARTDATE
    )) as fhir 
FROM
	fhir_procedure
