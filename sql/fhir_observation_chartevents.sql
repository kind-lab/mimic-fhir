DROP TABLE IF EXISTS mimic_fhir.observation_chartevents;
CREATE TABLE mimic_fhir.observation_chartevents(
	id 		uuid PRIMARY KEY,
  	fhir 	jsonb NOT NULL 
);

WITH vars as (
	SELECT
  		uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'EncounterICU') as uuid_encounter_icu
  		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Patient') as uuid_patient
 		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'ObservationChartevents') as uuid_observation_ce
  		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Specimen') as uuid_specimen
), fhir_observation_ce as (
	SELECT  		
  		ce.itemid as ce_ITEMID
  		, ce.charttime as ce_CHARTTIME
  		, ce.storetime as ce_STORETIME   		
  		, ce.valueuom as ce_VALUEUOM
  		, ce.valuenum as ce_VALUENUM
  		, ce.value as ce_VALUE
  		, di.label as di_LABEL
  		, di.category as di_CATEGORY
  		, di.lownormalvalue as di_LOWNORMALVALUE
  		, di.highnormalvalue as di_HIGHNORMALVALUE 		
  
  		-- refernce uuids
  		, uuid_generate_v5(uuid_observation_ce, 
                           ce.stay_id || '-' ||ce.charttime || '-' || ce.itemid) as uuid_CHARTEVENT
  		, uuid_generate_v5(uuid_patient, ce.subject_id::text) as uuid_SUBJECT_ID
  		, uuid_generate_v5(uuid_encounter_icu, ce.stay_id::text) as uuid_STAY_ID
  	FROM
  		mimic_icu.chartevents ce
  		LEFT JOIN mimic_icu.d_items di
  			ON ce.itemid = di.itemid
  		LEFT JOIN vars ON true
)
INSERT INTO mimic_fhir.observation_chartevents
SELECT 
	uuid_CHARTEVENT as id
	, jsonb_strip_nulls(jsonb_build_object(
    	'resourceType', 'Observation'
        , 'id', uuid_CHARTEVENT		 
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
                , 'code', ce_ITEMID
                , 'display', di_LABEL
            ))
          )
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'encounter', jsonb_build_object('reference', 'Encounter/' || uuid_STAY_ID) 
        , 'effectiveDateTime', ce_CHARTTIME
        , 'issued', ce_STORETIME
      	, 'valueQuantity', 
            CASE WHEN ce_VALUENUM IS NOT NULL THEN
               jsonb_build_object(
                 'value', ce_VALUENUM
                 , 'unit', ce_VALUEUOM
                 , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/lab-units'
                 , 'code', ce_VALUEUOM 
               ) 
            ELSE NULL
            END
        , 'valueString', 
      		CASE WHEN ce_VALUENUM IS NULL THEN
      			ce_VALUE
      		ELSE NULL
      		END          
        , 'referenceRange', 
      	   CASE WHEN di_LOWNORMALVALUE IS NOT NULL OR di_HIGHNORMALVALUE IS NOT NULL THEN	
              jsonb_build_array(jsonb_build_object(
                'low', 
                  CASE WHEN di_LOWNORMALVALUE IS NOT NULL THEN
                      jsonb_build_object(
                        'value', di_LOWNORMALVALUE
                        , 'unit', ce_VALUEUOM
                        , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/lab-units'
                        , 'code', ce_VALUEUOM
                       )
                  ELSE NULL
                  END
                 , 'high', 
                	CASE WHEN di_HIGHNORMALVALUE IS NOT NULL THEN
                		jsonb_build_object(
                          'value', di_HIGHNORMALVALUE
                          , 'unit', ce_VALUEUOM
                          , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/lab-units'
                          , 'code', ce_VALUEUOM
                       )
                	ELSE NULL
                	END
              ))
      	  ELSE NULL
      	  END
    )) as fhir 
FROM
	fhir_observation_ce
LIMIT 10
