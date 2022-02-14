-- Purpose: Generate a FHIR Observation resource for each datetimeevents row 
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit

DROP TABLE IF EXISTS mimic_fhir.observation_datetimeevents;
CREATE TABLE mimic_fhir.observation_datetimeevents(
	id 		uuid PRIMARY KEY,
	patient_id  uuid NOT NULL,
  	fhir 	jsonb NOT NULL 
);

WITH fhir_observation_de AS (
	SELECT  		
  		CAST(de.itemid AS TEXT) AS de_ITEMID
  		, CAST(de.charttime AS TIMESTAMPTZ) AS de_CHARTTIME
  		, CAST(de.storetime AS TIMESTAMPTZ) AS de_STORETIME   		
  		, CAST(de.value AS TIMESTAMPTZ) AS de_VALUE
  		, di.label AS di_LABEL
  		, di.category AS di_CATEGORY	
  
  		-- refernce uuids
  		, uuid_generate_v5(ns_observation_de.uuid, de.stay_id || '-' || de.charttime || '-' || de.itemid) as uuid_DATETIMEEVENT
  		, uuid_generate_v5(ns_patient.uuid, CAST(de.subject_id AS TEXT)) AS uuid_SUBJECT_ID
  		, uuid_generate_v5(ns_encounter_icu.uuid, CAST(de.stay_id AS TEXT)) AS uuid_STAY_ID
  	FROM
  		mimic_icu.datetimeevents de
  		INNER JOIN fhir_etl.subjects sub
  			ON de.subject_id =sub.subject_id 
  		LEFT JOIN mimic_icu.d_items di
  			ON de.itemid = di.itemid
  		LEFT JOIN fhir_etl.uuid_namespace ns_encounter_icu
  			ON ns_encounter_icu.name = 'EncounterICU'
  		LEFT JOIN fhir_etl.uuid_namespace ns_patient
  			ON ns_patient.name = 'Patient'
  		LEFT JOIN fhir_etl.uuid_namespace ns_observation_de
  			ON ns_observation_de.name = 'ObservationDatetimeevents'
)
INSERT INTO mimic_fhir.observation_datetimeevents
SELECT 
	uuid_DATETIMEEVENT as id
	, uuid_SUBJECT_ID AS patient_id 
	, jsonb_strip_nulls(jsonb_build_object(
    	'resourceType', 'Observation'
        , 'id', uuid_DATETIMEEVENT	
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://fhir.mimic.mit.edu/StructureDefinition/mimic-observation-datetime'
            )
        ) 
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
        , 'issued', de_STORETIME -- issued element is the instant the observation was available
      	, 'valueDateTime', de_VALUE -- Main value of interest from this resource 
    )) as fhir 
FROM
	fhir_observation_de
