WITH vars as (
	SELECT
  		uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Encounter') as uuid_encounter
  		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Patient') as uuid_patient
 		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Condition') as uuid_condition
), fhir_conditions as (
	SELECT
  		diag.hadm_id || '-' || diag.icd_code as diag_IDENTIFIER
  		, diag.icd_code as diag_ICD_CODE
  
  		-- refernce uuids
  		, uuid_generate_v5(uuid_condition, diag.hadm_id::text || '-' || diag.icd_code) as uuid_DIAGNOSIS
  		, uuid_generate_v5(uuid_patient, diag.subject_id::text) as uuid_SUBJECT_ID
  		, uuid_generate_v5(uuid_encounter, diag.hadm_id::text) as uuid_HADM_ID
  	FROM
  		mimic_hosp.diagnoses_icd diag
  		LEFT JOIN vars ON true
)

SELECT 
	uuid_DIAGNOSIS as id
	, jsonb_strip_nulls(jsonb_build_array(jsonb_build_object(
    	'resourceType', 'Condition'
        , 'id', uuid_DIAGNOSIS
      	, 'identifier', 
      		jsonb_build_array(
        		jsonb_build_object(
                  'value', diag_IDENTIFIER
                  , 'system', 'fhir.mimic-iv.ca/condition/identifier'
        		)
      		)		 
      	, 'clinicalStatus', jsonb_build_object(
          	'coding', jsonb_build_array(jsonb_build_object(
            	'system', 'http://terminology.hl7.org/CodeSystem/condition-clinical'  
                , 'code', 'active'
            ))
          )
        , 'category', jsonb_build_object(
          	'coding', jsonb_build_array(jsonb_build_object(
            	'system', 'http://hl7.org/fhir/us/core/ValueSet/us-core-condition-category'  
                , 'code', 'encounter-diagnosis'
            ))
          )
        , 'code', jsonb_build_object(
          	'coding', jsonb_build_array(jsonb_build_object(
            	'system', 'fhir.mimic-iv.ca/codesystem/icd9'  
                , 'code', diag_ICD_CODE
            ))
          )
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'encounter', jsonb_build_object('reference', 'Encounter' || uuid_HADM_ID) 
    ))) as fhir 
FROM
	fhir_conditions
LIMIT 10
