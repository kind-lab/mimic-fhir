-- Purpose: Generate a FHIR Encounter reosurce for each row in icustays
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit

DROP TABLE IF EXISTS mimic_fhir.encounter_icu;
CREATE TABLE mimic_fhir.encounter_icu(
	id 		uuid PRIMARY KEY,
  	fhir 	jsonb NOT NULL 
);

WITH fhir_encounter_icu AS (
	SELECT 
  		CAST(icu.stay_id AS TEXT) AS icu_STAY_ID
  		, icu.first_careunit AS icu_FIRST_CAREUNIT
  		, icu.last_careunit AS icu_LAST_CAREUNIT
  		, CAST(icu.intime AS TIMESTAMPTZ) AS icu_INTIME
  		, CAST(icu.outtime AS TIMESTAMPTZ) AS icu_OUTTIME
  		, icu.los AS icu_LOS  		
  	
  		-- reference uuids
  		, uuid_generate_v5(ns_encounter_icu.uuid, CAST(icu.stay_id AS TEXT)) AS uuid_STAY_ID
  		, uuid_generate_v5(ns_encounter.uuid, CAST(icu.hadm_id AS TEXT)) AS uuid_HADM_ID
  		, uuid_generate_v5(ns_patient.uuid, CAST(icu.subject_id AS TEXT)) AS uuid_SUBJECT_ID
 	FROM 
  		mimic_icu.icustays icu
  		INNER JOIN fhir_etl.subjects sub
  			ON icu.subject_id = sub.subject_id 
 		LEFT JOIN fhir_etl.uuid_namespace ns_encounter	
			ON ns_encounter.name = 'Encounter'
		LEFT JOIN fhir_etl.uuid_namespace ns_patient	
			ON ns_patient.name = 'Patient'
		LEFT JOIN fhir_etl.uuid_namespace ns_encounter_icu
			ON ns_encounter_icu.name = 'EncounterICU'
)

INSERT INTO mimic_fhir.encounter_icu
SELECT  
	uuid_STAY_ID as id
	, jsonb_strip_nulls(jsonb_build_object(
      	 'resourceType', 'Encounter'
         , 'id', uuid_STAY_ID
         , 'identifier', 
      		jsonb_build_array(
        		jsonb_build_object(
                  'value', icu_STAY_ID
                  , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/identifier-encounter-icu'
        		)
      		)	
      	 , 'status', 'finished' -- ALL encounters considered finished
         , 'class', jsonb_build_object(
              'system', 'http://fhir.mimic.mit.edu/CodeSystem/admission-class'
              , 'display', 'ACUTE'
           )
           
         -- Type of admission set based on the careunit visisted during ICU stay   
         , 'type', jsonb_build_array(jsonb_build_object(
         		'coding', jsonb_build_array(json_build_object(
                	'system', 'http://fhir.mimic.mit.edu/CodeSystem/admission-type-icu'
                    , 'display', icu_FIRST_CAREUNIT
                ))
           ))
      	 , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
         , 'period', jsonb_build_object(
         	  'start', icu_INTIME
              , 'end', icu_OUTTIME
         )
      	 , 'partOf', jsonb_build_object('reference', 'Encounter/' || uuid_HADM_ID)
        
	)) as fhir
FROM 
	fhir_encounter_icu
