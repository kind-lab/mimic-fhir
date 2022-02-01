-- Purpose: Generate a FHIR Observation resource for each unique specimen, test, and organism
--          found in microbiologyevents
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit

DROP TABLE IF EXISTS mimic_fhir.observation_micro_org;
CREATE TABLE mimic_fhir.observation_micro_org(
	id 		    uuid PRIMARY KEY, 
	patient_id  uuid NOT NULL,
  	fhir 	    jsonb NOT NULL 
);

-- Aggregate susceptiblities by organism for each patient specimen
WITH micro_info AS (
    SELECT 
        mi.micro_specimen_id AS micro_specimen_id 
        , CAST(mi.org_itemid AS TEXT) AS org_itemid
        , MAX(mi.test_itemid) AS test_itemid 
        , MAX(mi.org_name) AS org_name
        , MAX(mi.subject_id) AS subject_id
 		, MAX(CAST(mi.charttime AS TIMESTAMPTZ)) AS charttime
    
        -- Add a reference to susceptibility if an organism is tested for antibiotics
        , CASE WHEN MIN(mi.ab_itemid) IS NULL THEN NULL
          ELSE 
            jsonb_agg(
              jsonb_build_object('reference', 'Observation/' || uuid_generate_v5(ns_observation_micro_susc.uuid, 
                                               mi.micro_specimen_id || '-' ||
                                               mi.org_itemid || '-' ||
                                               mi.isolate_num || '-' ||
                                               mi.ab_itemid)
              ) 
            )
          END as fhir_SUSCEPTIBILITY
    FROM 
        mimic_hosp.microbiologyevents mi
        INNER JOIN fhir_etl.subjects sub
        	ON mi.subject_id = sub.subject_id
  		LEFT JOIN fhir_etl.uuid_namespace ns_observation_micro_susc
  			ON ns_observation_micro_susc.name = 'ObservationMicroSusc'
  	WHERE
  		mi.org_itemid IS NOT NULL
    GROUP BY 
        org_itemid
        , test_itemid
        , micro_specimen_id

), fhir_observation_micro_org AS (
    SELECT 
        mi.org_itemid AS mi_ORG_ITEMID
        , mi.org_name AS mi_ORG_NAME
 		, mi.charttime AS mi_CHARTTIME

        -- UUID references
        , uuid_generate_v5(ns_observation_micro_org.uuid, mi.test_itemid || '-' || mi.micro_specimen_id || '-' || mi.org_itemid) AS uuid_MICRO_ORG
        , uuid_generate_v5(ns_observation_micro_test.uuid, mi.micro_specimen_id || '-' || mi.test_itemid) AS uuid_MICRO_TEST
        , uuid_generate_v5(ns_patient.uuid, CAST(mi.subject_id AS TEXT)) AS uuid_SUBJECT_ID
        , fhir_SUSCEPTIBILITY
    FROM 
        micro_info mi
  		LEFT JOIN fhir_etl.uuid_namespace ns_patient
  			ON ns_patient.name = 'Patient'
  		LEFT JOIN fhir_etl.uuid_namespace ns_observation_micro_test
  			ON ns_observation_micro_test.name = 'ObservationMicroTest'
  		LEFT JOIN fhir_etl.uuid_namespace ns_observation_micro_org
  			ON ns_observation_micro_org.name = 'ObservationMicroOrg'
  		LEFT JOIN fhir_etl.uuid_namespace ns_observation_micro_susc
  			ON ns_observation_micro_susc.name = 'ObservationMicroSusc'
)  
  
INSERT INTO mimic_fhir.observation_micro_org  
SELECT 
    uuid_MICRO_ORG AS id
    , uuid_SUBJECT_ID  AS patient_id
	, jsonb_strip_nulls(jsonb_build_object(
    	  'resourceType', 'Observation'
        , 'id', uuid_MICRO_ORG 
        , 'meta', jsonb_build_object(
        	'profile', jsonb_build_array(
        		'http://fhir.mimic.mit.edu/StructureDefinition/mimic-observation-micro-org'
        	)
        ) 
        , 'status', 'final'        
        , 'category', jsonb_build_array(jsonb_build_object(
          	'coding', jsonb_build_array(jsonb_build_object(
            	'system', 'http://terminology.hl7.org/CodeSystem/observation-category'  
                , 'code', 'laboratory' 
            ))
          ))
          
        -- Organism item code  
      	, 'code', jsonb_build_object(
          	'coding', jsonb_build_array(jsonb_build_object(
            	'system', 'http://fhir.mimic.mit.edu/CodeSystem/microbiology-organism'  
                , 'code', mi_ORG_ITEMID
                , 'display', mi_ORG_NAME
            ))
          )
      	, 'effectiveDateTime', mi_CHARTTIME
		, 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'hasMember', fhir_SUSCEPTIBILITY -- Reference one to many antiobiotic susceptiblities 
        , 'derivedFrom', jsonb_build_array(jsonb_build_object('reference', 'Observation/' || uuid_MICRO_TEST))
    )) AS fhir 
FROM
    fhir_observation_micro_org
