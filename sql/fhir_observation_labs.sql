WITH vars as (
	SELECT
  		uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Encounter') as uuid_encounter
  		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Patient') as uuid_patient
 		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Observation-Labs') as uuid_observation_lab
  		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Specimen') as uuid_specimen
), fhir_observation_labs as (
	SELECT
  		lab.labevent_id as lab_LABEVENT_ID 
  		, dlab.loinc_code as dlab_LOINC_CODE
  		, lab.charttime as lab_CHARTTIME
  		, lab.storetime as lab_STORETIME
  		, lab.flag as lab_FLAG
  		, lab.comments as lab_COMMENTS
   		, lab.ref_range_lower as lab_REF_RANGE_LOWER
  		, lab.ref_range_upper as lab_REF_RANGE_UPPER
  		, lab.valueuom as lab_VALUEUOM
  		, lab.value as lab_VALUE
  
  		-- comparator
        , CASE 
            WHEN value LIKE '%<%' THEN split_part(lab.value,'<',2)::numeric
            WHEN value LIKE '%>%' THEN split_part(lab.value,'>',2)::numeric
            ELSE lab.valuenum
        END as lab_VALUENUM
        , CASE 
             WHEN value LIKE '%<%' THEN '<'
             WHEN value LIKE '%>%' THEN '>'
             ELSE NULL
          END as VALUE_COMPARATOR
  		
  
  		-- refernce uuids
  		, uuid_generate_v5(uuid_observation_lab, lab.labevent_id::text) as uuid_LABEVENT_ID
  		, uuid_generate_v5(uuid_patient, lab.subject_id::text) as uuid_SUBJECT_ID
  		, uuid_generate_v5(uuid_encounter, lab.hadm_id::text) as uuid_HADM_ID
  		, uuid_generate_v5(uuid_encounter, lab.specimen_id::text) as uuid_SPECIMEN_ID
  	FROM
  		mimic_hosp.labevents lab
  		LEFT JOIN mimic_hosp.d_labitems dlab
  			ON lab.itemid = dlab.itemid
  		LEFT JOIN vars ON true
)

SELECT 
	uuid_LABEVENT_ID as id
	, jsonb_strip_nulls(jsonb_build_array(jsonb_build_object(
    	'resourceType', 'Observation'
        , 'id', uuid_LABEVENT_ID
      	, 'identifier', 
      		jsonb_build_array(
        		jsonb_build_object(
                  'value', lab_LABEVENT_ID
                  , 'system', 'fhir.mimic-iv.ca/observation-labs/identifier'
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
            	'system', 'fhir.mimic-iv.ca/codesystem/loinc'  
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
                 , 'system', 'fhir.mimic-iv.ca/codesystem/lab_units'
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
                      'system', 'fhir.mimic-iv.ca/codesystem/lab_flags'  
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
                    , 'system', 'fhir.mimic-iv.ca/codesystem/lab_units'
                    , 'code', lab_VALUEUOM
                 )
                 , 'high', jsonb_build_object(
                      'value', lab_REF_RANGE_UPPER
                      , 'unit', lab_VALUEUOM
                      , 'system', 'fhir.mimic-iv.ca/codesystem/lab_units'
                      , 'code', lab_VALUEUOM
                   )
              ))
      	  ELSE NULL
      	  END
    ))) as fhir 
FROM
	fhir_observation_labs
WHERE lab_VALUENUM IS NOT NULL AND VALUE_COMPARATOR IS NOT NULL
LIMIT 10
