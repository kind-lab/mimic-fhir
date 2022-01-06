DROP TABLE IF EXISTS mimic_fhir.observation_micro_test;
CREATE TABLE mimic_fhir.observation_micro_test(
	id 		uuid PRIMARY KEY,
  	fhir 	jsonb NOT NULL 
);

WITH distinct_org AS (
	SELECT DISTINCT
		mi.micro_specimen_id  AS mi_MICRO_SPECIMEN_ID
        , CAST(mi.test_itemid AS TEXT) AS mi_TEST_ITEMID
        , mi.test_name AS mi_TEST_NAME
        , mi.subject_id AS mi_SUBJECT_ID
        , mi.hadm_id AS mi_HADM_ID
        , CAST(mi.charttime AS TIMESTAMPTZ) AS mi_CHARTTIME

        -- UUID references
        , uuid_generate_v5(ns_observation_micro_test.uuid, mi.micro_specimen_id || '-' || mi.test_itemid) AS uuid_MICRO_TEST
        , uuid_generate_v5(ns_patient.uuid, CAST(mi.subject_id AS TEXT)) AS uuid_SUBJECT_ID
        , uuid_generate_v5(ns_encounter.uuid, CAST(mi.hadm_id AS TEXT)) AS uuid_HADM_ID	
		
		, CASE WHEN MIN(mi.org_itemid) IS NULL THEN NULL 
		  ELSE
	        jsonb_build_object('reference', 
	                        'Observation/' || uuid_generate_v5(ns_observation_micro_org.uuid, mi.micro_specimen_id || '-' || mi.org_itemid)
	          ) 
	      END as fhir_ORGANISMS
	    , CASE WHEN MIN(mi.org_itemid) IS NULL THEN FALSE ELSE TRUE END AS valueBoolean
	FROM 
	    mimic_hosp.microbiologyevents mi
	   	INNER JOIN fhir_etl.subjects sub
	   		ON mi.subject_id = sub.subject_id 
	   	LEFT JOIN fhir_etl.uuid_namespace ns_patient
  			ON ns_patient.name = 'Patient'
  			LEFT JOIN fhir_etl.uuid_namespace ns_encounter
  			ON ns_encounter.name = 'Encounter'
  		LEFT JOIN fhir_etl.uuid_namespace ns_observation_micro_test
  			ON ns_observation_micro_test.name = 'ObservationMicroTest'
  		LEFT JOIN fhir_etl.uuid_namespace ns_observation_micro_org
  			ON ns_observation_micro_org.name = 'ObservationMicroOrg'
	GROUP BY 
	     test_itemid
        , test_name
        , micro_specimen_id
        , mi.subject_id
        , org_itemid
        , charttime
        , hadm_id
        , ns_patient.uuid
        , ns_encounter.uuid
        , ns_observation_micro_test.uuid
        , ns_observation_micro_org.uuid
), fhir_observation_micro_test AS (
	SELECT 
		mi_MICRO_SPECIMEN_ID
	    , mi_TEST_ITEMID
	    , mi_TEST_NAME
	    , mi_SUBJECT_ID
	    , mi_HADM_ID
	    , mi_CHARTTIME
	    , uuid_MICRO_TEST
	    , uuid_SUBJECT_ID
	    , uuid_HADM_ID
	    , valueBoolean
		, CASE WHEN valueBoolean THEN json_agg(fhir_ORGANISMS) 
		  ELSE NULL END AS fhir_ORGANISMS
	FROM 
		distinct_org
	GROUP BY 
	    mi_MICRO_SPECIMEN_ID
	    , mi_TEST_ITEMID
	    , mi_TEST_NAME
	    , mi_SUBJECT_ID
	    , mi_HADM_ID
	    , mi_CHARTTIME
	    , uuid_MICRO_TEST
	    , uuid_SUBJECT_ID
	    , uuid_HADM_ID
	    , valueBoolean
)
INSERT INTO mimic_fhir.observation_micro_test  
SELECT 
	  uuid_MICRO_TEST AS id
	  , jsonb_strip_nulls(jsonb_build_object(
    	'resourceType', 'Observation'
        , 'id', uuid_MICRO_TEST	 
        , 'status', 'final'        
        , 'category', jsonb_build_array(jsonb_build_object(
          	'coding', jsonb_build_array(jsonb_build_object(
            	'system', 'http://terminology.hl7.org/CodeSystem/observation-category'  
                , 'code', 'laboratory'
            ))
          ))
      	, 'code', jsonb_build_object(
          	'coding', jsonb_build_array(jsonb_build_object(
            	'system', 'http://fhir.mimic.mit.edu/CodeSystem/microbiology-test'  
                , 'code', mi_TEST_ITEMID
                , 'display', mi_TEST_NAME
            ))
          )
		    , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'encounter', 
      		CASE WHEN uuid_HADM_ID IS NOT NULL THEN
      		    jsonb_build_object('reference', 'Encounter/' || uuid_HADM_ID) 
      		ELSE NULL
      		END
        , 'effectiveDateTime', mi_CHARTTIME
        , 'hasMember', fhir_ORGANISMS
      	, 'valueBoolean', valueBoolean
    )) AS fhir 
FROM
    fhir_observation_micro_test
