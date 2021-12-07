DROP TABLE IF EXISTS mimic_fhir.observation_micro_susc;
CREATE TABLE mimic_fhir.observation_micro_susc(
	id 		uuid PRIMARY KEY,
  	fhir 	jsonb NOT NULL 
);

WITH vars as (
	SELECT
  		uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Encounter') as uuid_encounter
  		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Patient') as uuid_patient
 		, uuid_generate_v5(uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Observation'), 'micro-susc') as uuid_observation_micro_susc
), fhir_observation_micro_susc as (
  SELECT 
      mi.micro_specimen_id  as mi_MICRO_SPECIMEN_ID
      , mi.ab_itemid as mi_AB_ITEMID
      , mi.ab_name as mi_AB_NAME
      , mi.subject_id as mi_SUBJECT_ID
  	  , mi.interpretation as mi_INTERPRETATION
  	  , mi.storetime as mi_STORETIME

      -- UUID references
      , uuid_generate_v5(uuid_observation_micro_susc, mi.micro_specimen_id::text || '-' || mi.ab_itemid) as uuid_MICRO_SUSC
      , uuid_generate_v5(uuid_patient, mi.subject_id::text) as uuid_SUBJECT_ID

  FROM 
      mimic_hosp.microbiologyevents mi
      LEFT JOIN vars ON true
  WHERE 
  	 mi.interpretation IS NOT NULL
)  
  
INSERT INTO mimic_fhir.observation_micro_susc  
SELECT 
	uuid_MICRO_SUSC as id
	, jsonb_strip_nulls(jsonb_build_object(
    	'resourceType', 'Observation'
        , 'id', uuid_MICRO_SUSC 
        , 'status', 'final'        
        , 'category', jsonb_build_object(
          	'coding', jsonb_build_array(jsonb_build_object(
            	'system', 'http://terminology.hl7.org/CodeSystem/observation-category'  
                , 'code', 'laboratory'
            ))
          )
      	, 'code', jsonb_build_object(
          	'coding', jsonb_build_array(jsonb_build_object(
            	'system', 'fhir.mimic-iv.ca/codesystem/microbiology-susc'  
                , 'code', mi_AB_ITEMID
                , 'display', mi_AB_NAME
            ))
          )
		, 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'effectiveDateTime', mi_STORETIME
        , 'interpretation', jsonb_build_object(
          	'coding', jsonb_build_array(jsonb_build_object(
            	'system', 'fhir.mimic-iv.ca/codesystem/microbiology-interpretation'  
                , 'code', mi_INTERPRETATION
            ))
          )
    )) as fhir 
FROM
	fhir_observation_micro_susc
LIMIT 10
