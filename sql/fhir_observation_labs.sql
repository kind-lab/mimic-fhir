DROP TABLE IF EXISTS mimic_fhir.observation_labs;
CREATE TABLE mimic_fhir.observation_labs(
	id 		uuid PRIMARY KEY,
  	fhir 	jsonb NOT NULL 
);

WITH vars as (
	SELECT
  		uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Encounter') as uuid_encounter
  		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Patient') as uuid_patient
 		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Observation-Labs') as uuid_observation_lab
  		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Specimen') as uuid_specimen
), fhir_observation_labs AS (
	SELECT
  		CAST(lab.labevent_id AS TEXT) AS lab_LABEVENT_ID 
  		, dlab.loinc_code as dlab_LOINC_CODE
  		, CAST(lab.charttime AS TIMESTAMPTZ) AS lab_CHARTTIME
  		, CAST(lab.storetime AS TIMESTAMPTZ) AS lab_STORETIME
  		, lab.flag AS lab_FLAG
  		, lab.comments AS lab_COMMENTS
   		, lab.ref_range_lower AS lab_REF_RANGE_LOWER
  		, lab.ref_range_upper AS lab_REF_RANGE_UPPER
  		, lab.valueuom AS lab_VALUEUOM
  		, lab.value AS lab_VALUE
  
  		-- comparator
        , CASE 
  			WHEN value LIKE '%<=%' THEN CAST(split_part(lab.value,'<=',2) AS NUMERIC)
            WHEN value LIKE '%<%' THEN CAST(split_part(lab.value,'<',2) AS NUMERIC)
  			WHEN value LIKE '%>=%' THEN CAST(split_part(lab.value,'>=',2) AS NUMERIC)
            WHEN value LIKE '%>%' THEN CAST(split_part(lab.value,'>',2) AS NUMERIC)
            ELSE lab.valuenum
        END as lab_VALUENUM
        , CASE 
  			 WHEN value LIKE '%<=%' THEN '<='
             WHEN value LIKE '%<%' THEN '<'
  			 WHEN value LIKE '%>=%' THEN '>='
             WHEN value LIKE '%>%' THEN '>'
             ELSE NULL
          END as VALUE_COMPARATOR
  		
  
  		-- refernce uuids
  		, uuid_generate_v5(uuid_observation_lab, CAST(lab.labevent_id AS TEXT)) AS uuid_LABEVENT_ID
  		, uuid_generate_v5(uuid_patient, CAST(lab.subject_id AS TEXT)) AS uuid_SUBJECT_ID
  		, uuid_generate_v5(uuid_encounter, CAST(lab.hadm_id AS TEXT)) AS uuid_HADM_ID
  		, uuid_generate_v5(uuid_encounter, CAST(lab.specimen_id AS TEXT)) AS uuid_SPECIMEN_ID
  	FROM
  		mimic_hosp.labevents lab
  		INNER JOIN fhir_etl.subjects sub
  			ON lab.subject_id =sub.subject_id 
  		LEFT JOIN mimic_hosp.d_labitems dlab
  			ON lab.itemid = dlab.itemid
  		LEFT JOIN vars ON true
)
INSERT INTO mimic_fhir.observation_labs
SELECT 
	uuid_LABEVENT_ID as id
	, jsonb_strip_nulls(jsonb_build_object(
    	'resourceType', 'Observation'
        , 'id', uuid_LABEVENT_ID
      	, 'identifier', 
      		jsonb_build_array(
        		jsonb_build_object(
                  'value', lab_LABEVENT_ID
                  , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/identifier-observation-labs'
        		)
      		)		 
        , 'status', 'final'
      	, 'category', jsonb_build_array(jsonb_build_object(
          	'coding', jsonb_build_array(jsonb_build_object(
            	'system', 'http://terminology.hl7.org/CodeSystem/observation-category'  
                , 'code', 'laboratory'
            ))
          ))
        , 'code', jsonb_build_object(
          	'coding', jsonb_build_array(jsonb_build_object(
            	'system', 'http://fhir.mimic.mit.edu/CodeSystem/loinc'  
                , 'code', dlab_LOINC_CODE
            ))
          )
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'encounter', 
      		CASE WHEN uuid_HADM_ID IS NOT NULL
      		  THEN jsonb_build_object('reference', 'Encounter/' || uuid_HADM_ID) 
      		  ELSE NULL
      		END
        , 'effectiveDateTime', lab_CHARTTIME
        , 'issued', lab_STORETIME
      	, 'valueQuantity', 
            CASE WHEN lab_VALUENUM IS NOT NULL THEN
               jsonb_build_object(
                 'value', lab_VALUENUM
                 , 'unit', lab_VALUEUOM
                 , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/lab-units'
                 , 'code', lab_VALUEUOM 
                 , 'comparator', VALUE_COMPARATOR
               ) 
            ELSE NULL
            END
        , 'valueString', 
      		CASE WHEN lab_VALUENUM IS NULL THEN
      			lab_VALUE
      		ELSE NULL
      		END
      
      	, 'interpretation', 
      		CASE WHEN lab_FLAG IS NOT NULL THEN
      			jsonb_build_array(jsonb_build_object(
                  'coding', jsonb_build_array(jsonb_build_object(
                      'system', 'http://fhir.mimic.mit.edu/CodeSystem/lab-flags'  
                      , 'code', lab_FLAG
                  ))
                ))
      	    ELSE NULL
      	    END
        , 'note', 
      		CASE WHEN lab_COMMENTS IS NOT NULL THEN
      			jsonb_build_array(jsonb_build_object(
                  'text', lab_COMMENTS
                ))
      	    ELSE NULL
      	    END
        , 'specimen', jsonb_build_object('reference', 'Specimen/' || uuid_SPECIMEN_ID) 
        , 'referenceRange', 
      	   CASE WHEN lab_REF_RANGE_LOWER IS NOT NULL THEN	
              jsonb_build_array(jsonb_build_object(
                'low', jsonb_build_object(
                    'value', lab_REF_RANGE_LOWER
                    , 'unit', lab_VALUEUOM
                    , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/lab-units'
                    , 'code', lab_VALUEUOM
                 )
                 , 'high', jsonb_build_object(
                      'value', lab_REF_RANGE_UPPER
                      , 'unit', lab_VALUEUOM
                      , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/lab-units'
                      , 'code', lab_VALUEUOM
                   )
              ))
      	  ELSE NULL
      	  END
    )) as fhir 
FROM
	fhir_observation_labs
