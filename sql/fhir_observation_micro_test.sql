DROP TABLE IF EXISTS mimic_fhir.observation_micro_test;
CREATE TABLE mimic_fhir.observation_micro_test(
	id 		uuid PRIMARY KEY,
  	fhir 	jsonb NOT NULL 
);

WITH vars as (
	SELECT
  		uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Encounter') as uuid_encounter
  		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Patient') as uuid_patient
 		, uuid_generate_v5(uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Observation'), 'micro-test') as uuid_observation_micro_test
  		, uuid_generate_v5(uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Observation'), 'micro-org') as uuid_observation_micro_org
), fhir_observation_micro_test as (
  SELECT 
      mi.micro_specimen_id  as mi_MICRO_SPECIMEN_ID
      , mi.test_itemid as mi_TEST_ITEMID
      , mi.test_name as mi_TEST_NAME
      , mi.subject_id as mi_SUBJECT_ID
      , mi.hadm_id as mi_HADM_ID
      , mi.charttime as mi_CHARTTIME

      -- UUID references
      , uuid_generate_v5(uuid_observation_micro_test, mi.micro_specimen_id::text || '-' || mi.test_itemid) as uuid_MICRO_TEST
      , uuid_generate_v5(uuid_patient, mi.subject_id::text) as uuid_SUBJECT_ID
      , uuid_generate_v5(uuid_encounter, mi.hadm_id::text) as uuid_HADM_ID
      , jsonb_agg(
            jsonb_build_object('reference', 
                               'Observation/' || uuid_generate_v5(uuid_observation_micro_org, mi.micro_specimen_id::text || '-' || mi.org_itemid)
            ) 
        ) as fhir_ORGANISMS

  FROM 
      mimic_hosp.microbiologyevents mi
      LEFT JOIN vars ON true
  GROUP BY 
      test_itemid
      , test_name
      , micro_specimen_id
      , subject_id
      , charttime
      , hadm_id
  	  , uuid_patient
  	  , uuid_encounter
  	  , uuid_observation_micro_test
  	  , uuid_observation_micro_org

  LIMIT 1000
)  
  
INSERT INTO mimic_fhir.observation_micro_test  
SELECT 
	uuid_MICRO_TEST as id
	, jsonb_strip_nulls(jsonb_build_object(
    	'resourceType', 'Observation'
        , 'id', uuid_MICRO_TEST	 
        , 'status', 'final'        
        , 'category', jsonb_build_object(
          	'coding', jsonb_build_array(jsonb_build_object(
            	'system', 'http://terminology.hl7.org/CodeSystem/observation-category'  
                , 'code', 'laboratory'
            ))
          )
      	, 'code', jsonb_build_object(
          	'coding', jsonb_build_array(jsonb_build_object(
            	'system', 'fhir.mimic-iv.ca/codesystem/microbiology-test'  
                , 'code', mi_TEST_ITEMID
                , 'display', mi_TEST_NAME
            ))
          )
		, 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'encounter', 
      		CASE WHEN uuid_HADM_ID IS NOT NULL
      		  THEN jsonb_build_object('reference', 'Encounter/' || uuid_HADM_ID) 
      		  ELSE NULL
      		END
        , 'effectiveDateTime', mi_CHARTTIME
        , 'hasMember', fhir_ORGANISMS
    )) as fhir 
FROM
	fhir_observation_micro_test
LIMIT 10
