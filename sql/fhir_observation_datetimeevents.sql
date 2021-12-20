DROP TABLE IF EXISTS mimic_fhir.observation_datetimeevents;
CREATE TABLE mimic_fhir.observation_datetimeevents(
	id 		uuid PRIMARY KEY,
  	fhir 	jsonb NOT NULL 
);

WITH vars as (
	SELECT
  		uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'EncounterICU') as uuid_encounter_icu
  		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Patient') as uuid_patient
 		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'ObservationDatetimeevents') as uuid_observation_de
  		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Specimen') as uuid_specimen
), fhir_observation_de as (
	SELECT  		
  		de.itemid::text as de_ITEMID
  		, de.charttime::TIMESTAMPTZ as de_CHARTTIME
  		, de.storetime::TIMESTAMPTZ as de_STORETIME   		
  		, de.value::TIMESTAMPTZ as de_VALUE
  		, di.label as di_LABEL
  		, di.category as di_CATEGORY	
  
  		-- refernce uuids
  		, uuid_generate_v5(uuid_observation_de, 
                           de.stay_id || '-' || de.charttime || '-' || de.itemid) as uuid_DATETIMEEVENT
  		, uuid_generate_v5(uuid_patient, de.subject_id::text) as uuid_SUBJECT_ID
  		, uuid_generate_v5(uuid_encounter_icu, de.stay_id::text) as uuid_STAY_ID
  	FROM
  		mimic_icu.datetimeevents de
  		LEFT JOIN mimic_icu.d_items di
  			ON de.itemid = di.itemid
  		LEFT JOIN vars ON true
    WHERE
  		de.subject_id < 10010000  
)
INSERT INTO mimic_fhir.observation_datetimeevents
SELECT 
	uuid_DATETIMEEVENT as id
	, jsonb_strip_nulls(jsonb_build_object(
    	'resourceType', 'Observation'
        , 'id', uuid_DATETIMEEVENT		 
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
                , 'code', de_ITEMID
                , 'display', di_LABEL
            ))
          )
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'encounter', jsonb_build_object('reference', 'Encounter/' || uuid_STAY_ID) 
        , 'effectiveDateTime', de_CHARTTIME
        , 'issued', de_STORETIME
      	, 'valueDateTime', de_VALUE
    )) as fhir 
FROM
	fhir_observation_de
