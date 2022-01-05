DROP TABLE IF EXISTS mimic_fhir.observation_outputevents;
CREATE TABLE mimic_fhir.observation_outputevents(
	id 		uuid PRIMARY KEY,
  	fhir 	jsonb NOT NULL 
);

WITH vars as (
	SELECT
  		uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'EncounterICU') as uuid_encounter_icu
  		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Patient') as uuid_patient
 		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'ObservationOutputevents') as uuid_observation_oe
  		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Specimen') as uuid_specimen
), fhir_observation_oe AS (
	SELECT  		
  		CAST(oe.itemid AS TEXT) AS oe_ITEMID
  		, CAST(oe.charttime AS TIMESTAMPTZ) AS oe_CHARTTIME
  		, CAST(oe.storetime AS TIMESTAMPTZ) AS oe_STORETIME   		
  		, oe.valueuom AS oe_VALUEUOM
  		, oe.value AS oe_VALUE
  		, di.label AS di_LABEL
  		, di.category AS di_CATEGORY	
  
  		-- refernce uuids
  		, uuid_generate_v5(uuid_observation_oe, CONCAT_WS('-', oe.stay_id, oe.charttime, oe.itemid)) as uuid_OUTPUTEVENT
  		, uuid_generate_v5(uuid_patient, CAST(oe.subject_id AS TEXT)) AS uuid_SUBJECT_ID
  		, uuid_generate_v5(uuid_encounter_icu, CAST(oe.stay_id AS TEXT)) AS uuid_STAY_ID
  	FROM
  		mimic_icu.outputevents oe
  		INNER JOIN fhir_etl.subjects sub
  			ON oe.subject_id = sub.subject_id 
  		LEFT JOIN mimic_icu.d_items di
  			ON oe.itemid = di.itemid
  		LEFT JOIN vars ON true
)
INSERT INTO mimic_fhir.observation_outputevents
SELECT 
	uuid_OUTPUTEVENT AS id
	, jsonb_strip_nulls(jsonb_build_object(
    	'resourceType', 'Observation'
        , 'id', uuid_OUTPUTEVENT		 
        , 'status', 'final'
      	, 'category', jsonb_build_array(jsonb_build_object(
          	'coding', jsonb_build_array(jsonb_build_object(
            	'system', 'http://fhir.mimic.mit.edu/CodeSystem/observation-category'  
                , 'code', di_CATEGORY
            ))
          ))
        , 'code', jsonb_build_object(
          	'coding', jsonb_build_array(jsonb_build_object(
            	'system', 'http://fhir.mimic.mit.edu/CodeSystem/d-items'  
                , 'code', oe_ITEMID
                , 'display', di_LABEL
            ))
          )
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'encounter', jsonb_build_object('reference', 'Encounter/' || uuid_STAY_ID) 
        , 'effectiveDateTime', oe_CHARTTIME
        , 'issued', oe_STORETIME
      	, 'valueQuantity', 
               jsonb_build_object(
                 'value', oe_VALUE
                 , 'unit', oe_VALUEUOM
                 , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/lab-units'
                 , 'code', oe_VALUEUOM
               )      
    )) AS fhir 
FROM
	fhir_observation_oe
