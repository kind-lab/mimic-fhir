DROP TABLE IF EXISTS mimic_fhir.encounter_icu;
CREATE TABLE mimic_fhir.encounter_icu(
	id 		uuid PRIMARY KEY,
  	fhir 	jsonb NOT NULL 
);

WITH vars as (
	SELECT
  		uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Patient') as uuid_patient
 		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Encounter') as uuid_encounter
  		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'EncounterICU') as uuid_encounter_icu
), fhir_encounter_icu as (
	SELECT 
  		icu.stay_id::text as icu_STAY_ID
  		, icu.first_careunit as icu_FIRST_CAREUNIT
  		, icu.last_careunit as icu_LAST_CAREUNIT
  		, icu.intime::TIMESTAMPTZ as icu_INTIME
  		, icu.outtime::TIMESTAMPTZ as icu_OUTTIME
  		, icu.los as icu_LOS  		
  	
  		-- reference uuids
  		, uuid_generate_v5(uuid_encounter_icu, icu.stay_id::text) as uuid_STAY_ID
  		, uuid_generate_v5(uuid_encounter, icu.hadm_id::text) as uuid_HADM_ID
  		, uuid_generate_v5(uuid_patient, icu.subject_id::text) as uuid_SUBJECT_ID
 	FROM 
  		mimic_icu.icustays icu
 		LEFT JOIN vars ON true
    WHERE
  		icu.subject_id < 10010000
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
                  , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/identifier-encounter'
        		)
      		)	
      	 , 'status', 'finished'
         , 'class', jsonb_build_object(
              'system', 'fhir.mimic-iv.ca/valuest/admission-class'
              , 'display', 'ACUTE'
           )
         , 'type', jsonb_build_array(jsonb_build_object(
         		'coding', jsonb_build_array(json_build_object(
                	'system', 'http://fhir.mimic.mit.edu/ValueSet/admission-type-icu'
                    , 'display', icu_FIRST_CAREUNIT
                ))
           ))
      	 , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
         , 'period', jsonb_build_object(
         	  'start', icu_INTIME
              , 'end', icu_OUTTIME
         )
      	-- Add location for first_careunit and last_careunit (may need to make these into Location resources, discuss with Alistair)
      	 , 'partOf', jsonb_build_object('reference', 'Encounter/' || uuid_HADM_ID)
        
	)) as fhir
FROM 
	fhir_encounter_icu
