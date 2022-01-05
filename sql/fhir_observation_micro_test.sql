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
), fhir_observation_micro_test AS (
    SELECT 
        mi.micro_specimen_id  AS mi_MICRO_SPECIMEN_ID
        , CAST(mi.test_itemid AS TEXT) AS mi_TEST_ITEMID
        , mi.test_name AS mi_TEST_NAME
        , mi.subject_id AS mi_SUBJECT_ID
        , mi.hadm_id AS mi_HADM_ID
        , CAST(mi.charttime AS TIMESTAMPTZ) AS mi_CHARTTIME

        -- UUID references
        , uuid_generate_v5(uuid_observation_micro_test, mi.micro_specimen_id || '-' || mi.test_itemid) AS uuid_MICRO_TEST
        , uuid_generate_v5(uuid_patient, CAST(mi.subject_id AS TEXT)) AS uuid_SUBJECT_ID
        , uuid_generate_v5(uuid_encounter, CAST(mi.hadm_id AS TEXT)) AS uuid_HADM_ID
    
        -- organism will be null if the test found no organisms. So no organism/susceptibility resources needed to be made off this
        , CASE WHEN MIN(mi.org_itemid) IS NULL THEN NULL 
          ELSE
          jsonb_agg(
              jsonb_build_object('reference', 
                                'Observation/' || uuid_generate_v5(uuid_observation_micro_org, mi.micro_specimen_id || '-' || mi.org_itemid)
              ) 
            )
        END as fhir_ORGANISMS
    
        -- valueBoolean is used as a flag to say if there are any orgsanism, if yes true, if no false
        , CASE WHEN MIN(mi.org_itemid) IS NULL THEN FALSE ELSE TRUE END AS valueBoolean

    FROM 
       mimic_hosp.microbiologyevents mi
       INNER JOIN fhir_etl.subjects sub
       		ON mi.subject_id = sub.subject_id 
       LEFT JOIN vars ON true
    GROUP BY 
        test_itemid
        , test_name
        , micro_specimen_id
        , mi.subject_id
        , charttime
        , hadm_id
        , uuid_patient
        , uuid_encounter
        , uuid_observation_micro_test
        , uuid_observation_micro_org
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
