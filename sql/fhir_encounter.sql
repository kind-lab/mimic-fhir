DROP TABLE IF EXISTS mimic_fhir.encounter;
CREATE TABLE mimic_fhir.encounter(
	id 		uuid PRIMARY KEY,
  	fhir 	jsonb NOT NULL 
);

WITH vars as (
	SELECT
  		uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Encounter') as uuid_encounter
  		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Patient') as uuid_patient
 		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Condition') as uuid_condition
  		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Organization') as uuid_organization
), tb_diagnoses as (
    SELECT 
  		adm.hadm_id 
        ,  jsonb_agg(
          		jsonb_build_object('condition', 'Condition/' || uuid_generate_v5(uuid_condition, adm.hadm_id::text || '-' || diag.icd_code)
                             , 'rank', seq_num) 
          ORDER BY seq_num ASC) as fhir_DIAGNOSES
  
    FROM
		mimic_core.admissions adm
		LEFT JOIN mimic_hosp.diagnoses_icd diag
			ON adm.hadm_id = diag.hadm_id
		LEFT JOIN vars ON true
    GROUP BY
        adm.hadm_id
  		, uuid_condition
), fhir_encounter as (
	SELECT 
  		adm.hadm_id as adm_HADM_ID
  		
  		
  		, adm.admission_type as adm_ADMISSION_TYPE
  		, adm.admittime as adm_ADMITTIME
  		, adm.dischtime as adm_DISCHTIME
  		, adm.admission_location as adm_ADMISSION_LOCATION  		
  		, adm.discharge_location as adm_DISCHARGE_LOCATION  		
  		, diag.fhir_DIAGNOSES as fhir_DIAGNOSES
  	
  		-- reference uuids
  		, uuid_generate_v5(uuid_encounter, adm.hadm_id::text) as uuid_HADM_ID
  		, uuid_generate_v5(uuid_patient, adm.subject_id::text) as uuid_SUBJECT_ID
  		, uuid_generate_v5(uuid_organization, 'MIMIC Hospital') as uuid_ORG
 	FROM 
  		mimic_core.admissions adm
  		LEFT JOIN tb_diagnoses diag
  			ON adm.hadm_id = diag.hadm_id
 		LEFT JOIN vars ON true
)

INSERT INTO mimic_fhir.encounter
SELECT  
	uuid_HADM_ID as id
	, jsonb_strip_nulls(jsonb_build_object(
      	 'resourceType', 'Encounter'
         , 'id', uuid_HADM_ID
         , 'identifier', 
      		jsonb_build_array(
        		jsonb_build_object(
                  'value', adm_HADM_ID
                  , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/identifier-encounter'
        		)
      		)	
      	 , 'status', 'finished'
         , 'class', jsonb_build_object(
         	'system', 'fhir.mimic-iv.ca/valuest/admission-class'
            , 'display', adm_ADMISSION_TYPE
           )
         , 'type', jsonb_build_array(jsonb_build_object(
         		'coding', jsonb_build_array(json_build_object(
                	'system', 'http://fhir.mimic.mit.edu/ValueSet/admission-type'
                    , 'display', adm_ADMISSION_TYPE
                ))
           ))
      	 , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
         , 'period', jsonb_build_object(
         	  'start', adm_ADMITTIME
              , 'end', adm_DISCHTIME
         )
         , 'hospitalization', jsonb_build_object(
         	 'admitSource', 
               CASE WHEN adm_ADMISSION_LOCATION IS NOT NULL
           	   THEN jsonb_build_object(
                  'coding',  jsonb_build_array(jsonb_build_object(
                      'system', 'http://fhir.mimic.mit.edu/ValueSet/admit-source'
                      , 'display', adm_ADMISSION_LOCATION
                  ))                
            	)
           	   ELSE NULL
           	   END
           , 'dischargeDisposition', 
           	   CASE WHEN adm_DISCHARGE_LOCATION IS NOT NULL
           	   THEN jsonb_build_object(
                  'coding',  jsonb_build_array(jsonb_build_object(
                      'system', 'http://fhir.mimic.mit.edu/ValueSet/discharge-dispostion'
                      , 'display', adm_DISCHARGE_LOCATION
                  ))                
            	)
           	   ELSE NULL
           	   END
         )        
         , 'diagnosis', fhir_DIAGNOSES 
         , 'serviceProvider', jsonb_build_object('reference', 'Organization/' || uuid_ORG)	 		
	)) as fhir
FROM 
	fhir_encounter 
LIMIT 10
