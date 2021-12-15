DROP TABLE IF EXISTS mimic_fhir.observation_micro_org;
CREATE TABLE mimic_fhir.observation_micro_org(
	  id 		uuid PRIMARY KEY, 
  	fhir 	jsonb NOT NULL 
);

-- The formatting for the UUIDs is an example of how they could be, versus the oneliners I have in the other files, let me know what you think!
WITH vars as (
    SELECT
  		uuid_generate_v5(
        uuid_generate_v5(
          uuid_ns_oid(), 'MIMIC-IV'
        ), 'Encounter'
      ) as uuid_encounter
  		, uuid_generate_v5(
          uuid_generate_v5(
            uuid_ns_oid(), 'MIMIC-IV'
          ), 'Patient'
        ) as uuid_patient
 		  , uuid_generate_v5(
          uuid_generate_v5(
            uuid_generate_v5(
              uuid_ns_oid(), 'MIMIC-IV'
            ), 'Observation'
          ), 'micro-susc'
        ) as uuid_observation_micro_susc
  		, uuid_generate_v5(
          uuid_generate_v5(
            uuid_generate_v5(
              uuid_ns_oid(), 'MIMIC-IV'
            ), 'Observation'
          ), 'micro-org'
        ) as uuid_observation_micro_org
), fhir_observation_micro_org as (
    SELECT 
        mi.micro_specimen_id  as mi_MICRO_SPECIMEN_ID
        , mi.org_itemid as mi_ORG_ITEMID
        , mi.org_name as mi_ORG_NAME
        , mi.subject_id as mi_SUBJECT_ID

        -- UUID references
        , uuid_generate_v5(uuid_observation_micro_org, mi.micro_specimen_id::text || '-' || mi.org_itemid) as uuid_MICRO_ORG
        , uuid_generate_v5(uuid_patient, mi.subject_id::text) as uuid_SUBJECT_ID
    
        -- if organism is present but not tested for antibiotics, set NULL for susceptibility
        , CASE WHEN MIN(mi.ab_itemid) IS NULL THEN NULL
          ELSE 
            jsonb_agg(
              jsonb_build_object('reference', 
                                'Observation/' || uuid_generate_v5(uuid_observation_micro_susc, mi.micro_specimen_id::text || '-' || mi.ab_itemid)
              ) 
            )
          END as fhir_SUSCEPTIBILITY
    FROM 
        mimic_hosp.microbiologyevents mi
        LEFT JOIN vars ON true
    GROUP BY 
        org_itemid
        , org_name
        , micro_specimen_id
        , subject_id
        , uuid_patient
        , uuid_observation_micro_org
        , uuid_observation_micro_susc
)  
  
INSERT INTO mimic_fhir.observation_micro_org  
SELECT 
    uuid_MICRO_ORG as id
	  , jsonb_strip_nulls(jsonb_build_object(
    	  'resourceType', 'Observation'
        , 'id', uuid_MICRO_ORG 
        , 'status', 'final'        
        , 'category', jsonb_build_object(
          	'coding', jsonb_build_array(jsonb_build_object(
            	'system', 'http://terminology.hl7.org/CodeSystem/observation-category'  
                , 'code', 'laboratory'
            ))
          )
      	, 'code', jsonb_build_object(
          	'coding', jsonb_build_array(jsonb_build_object(
            	'system', 'http://fhir.mimic.mit.edu/CodeSystem/microbiology-organism'  
                , 'code', mi_ORG_ITEMID
                , 'display', mi_ORG_NAME
            ))
          )
		    , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'hasMember', fhir_SUSCEPTIBILITY
    )) as fhir 
FROM
    fhir_observation_micro_org
LIMIT 10
