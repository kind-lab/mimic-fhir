DROP TABLE IF EXISTS mimic_fhir.encounter;
CREATE TABLE mimic_fhir.encounter(
	id 		uuid PRIMARY KEY,
  	fhir 	jsonb NOT NULL 
);

WITH tb_diagnoses AS (
    SELECT 
  		adm.hadm_id 
        ,  jsonb_agg(
          		jsonb_build_object(
                  	'condition', jsonb_build_object(
                      		'reference', 'Condition/' || uuid_generate_v5(ns_condition.uuid, adm.hadm_id || '-' || diag.icd_code)
                      )
                    , 'rank', seq_num
                ) 
          ORDER BY seq_num ASC) AS fhir_DIAGNOSES
  
    FROM
		mimic_core.admissions adm
		LEFT JOIN mimic_hosp.diagnoses_icd diag
			ON adm.hadm_id = diag.hadm_id
		LEFT JOIN fhir_etl.uuid_namespace ns_condition 	
			ON ns_condition.name = 'Condition'
    GROUP BY
        adm.hadm_id
  		, ns_condition.uuid
), fhir_encounter AS (
	SELECT 
  		CAST(adm.hadm_id AS TEXT) AS adm_HADM_ID	
  		, adm.admission_type AS adm_ADMISSION_TYPE
  		, CAST(adm.admittime AS TIMESTAMPTZ) AS adm_ADMITTIME
  		, CAST(adm.dischtime AS TIMESTAMPTZ) AS adm_DISCHTIME
  		, adm.admission_location AS adm_ADMISSION_LOCATION  		
  		, adm.discharge_location AS adm_DISCHARGE_LOCATION  		
  		, diag.fhir_DIAGNOSES AS fhir_DIAGNOSES
  	
  		-- reference uuids
  		, uuid_generate_v5(ns_encounter.uuid, CAST(adm.hadm_id AS TEXT)) AS uuid_HADM_ID
  		, uuid_generate_v5(ns_patient.uuid, CAST(adm.subject_id AS TEXT)) AS uuid_SUBJECT_ID
  		, uuid_generate_v5(ns_organization.uuid, 'Beth Israel Deaconess Medical Center') AS uuid_ORG
 	FROM 
  		mimic_core.admissions adm
  		INNER JOIN fhir_etl.subjects sub
  			ON adm.subject_id = sub.subject_id 
  		LEFT JOIN tb_diagnoses diag
  			ON adm.hadm_id = diag.hadm_id
 		LEFT JOIN fhir_etl.uuid_namespace ns_encounter	
			ON ns_encounter.name = 'Encounter'
		LEFT JOIN fhir_etl.uuid_namespace ns_patient	
			ON ns_patient.name = 'Patient'
		LEFT JOIN fhir_etl.uuid_namespace ns_organization	
			ON ns_organization.name = 'Organization'
)

INSERT INTO mimic_fhir.encounter
SELECT  
	uuid_HADM_ID AS id
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
         	'system', 'http://fhir.mimic.mit.edu/CodeSystem/admission-class'
            , 'display', adm_ADMISSION_TYPE
           )
         , 'type', jsonb_build_array(jsonb_build_object(
         		'coding', jsonb_build_array(json_build_object(
                	'system', 'http://fhir.mimic.mit.edu/CodeSystem/admission-type'
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
                      'system', 'http://fhir.mimic.mit.edu/CodeSystem/admit-source'
                      , 'display', adm_ADMISSION_LOCATION
                  ))                
            	)
           	   ELSE NULL
           	   END
           , 'dischargeDisposition', 
           	   CASE WHEN adm_DISCHARGE_LOCATION IS NOT NULL
           	   THEN jsonb_build_object(
                  'coding',  jsonb_build_array(jsonb_build_object(
                      'system', 'http://fhir.mimic.mit.edu/CodeSystem/discharge-dispostion'
                      , 'display', adm_DISCHARGE_LOCATION
                  ))                
            	)
           	   ELSE NULL
           	   END
         )        
         , 'diagnosis', fhir_DIAGNOSES 
         , 'serviceProvider', jsonb_build_object('reference', 'Organization/' || uuid_ORG)	 		
	)) AS fhir
FROM 
	fhir_encounter 
