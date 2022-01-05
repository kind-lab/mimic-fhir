DROP TABLE IF EXISTS mimic_fhir.condition;
CREATE TABLE mimic_fhir.condition(
	id 		uuid PRIMARY KEY,
  	fhir 	jsonb NOT NULL 
);

WITH vars as (
	SELECT
  		uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Encounter') as uuid_encounter
  		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Patient') as uuid_patient
 		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Condition') as uuid_condition
), fhir_condition as (
	SELECT
  		CONCAT_WS('-', diag.hadm_id, diag.seq_num) as diag_IDENTIFIER
  		, TRIM(diag.icd_code) as diag_ICD_CODE -- remove whitespaces or FHIR validator will complain
  
  		-- refernce uuids
  		, uuid_generate_v5(uuid_condition, CONCAT_WS('-', diag.hadm_id, diag.seq_num, diag.icd_code)) as uuid_DIAGNOSIS
  		, uuid_generate_v5(uuid_patient, CAST(diag.subject_id AS TEXT)) as uuid_SUBJECT_ID
  		, uuid_generate_v5(uuid_encounter, CAST(diag.hadm_id AS TEXT)) as uuid_HADM_ID
  	FROM
  		mimic_hosp.diagnoses_icd diag
  		INNER JOIN fhir_etl.subjects sub
  			ON diag.subject_id =sub.subject_id 
  		LEFT JOIN vars ON true
)

INSERT INTO mimic_fhir.condition
SELECT 
	uuid_DIAGNOSIS as id
	, jsonb_strip_nulls(jsonb_build_object(
    	'resourceType', 'Condition'
        , 'id', uuid_DIAGNOSIS
      	, 'identifier', 
      		jsonb_build_array(
        		jsonb_build_object(
                  'value', diag_IDENTIFIER
                  , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/identifier-condition'
        		)
      		)		 
      	, 'clinicalStatus', jsonb_build_object(
          	'coding', jsonb_build_array(jsonb_build_object(
            	'system', 'http://terminology.hl7.org/CodeSystem/condition-clinical'  
                , 'code', 'active'
            ))
          )
        , 'category', jsonb_build_array(jsonb_build_object(
          	'coding', jsonb_build_array(jsonb_build_object(
            	'system', 'http://terminology.hl7.org/CodeSystem/condition-category'  
                , 'code', 'encounter-diagnosis'
            ))
          ))
        , 'code', jsonb_build_object(
          	'coding', jsonb_build_array(jsonb_build_object(
            	'system', 'http://fhir.mimic.mit.edu/CodeSystem/condition-icd9'  
                , 'code', diag_ICD_CODE
            ))
          )
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'encounter', jsonb_build_object('reference', 'Encounter/' || uuid_HADM_ID) 
    )) as fhir 
FROM
	fhir_condition
