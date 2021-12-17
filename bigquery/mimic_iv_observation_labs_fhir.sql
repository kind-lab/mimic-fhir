WITH fhir_observation_labs as (
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
        , COALESCE(
            lab.valuenum,
            CAST(REGEXP_EXTRACT(lab.value, r'[<>]=?\s*([0-9.]+)', 2) AS NUMERIC)
        ) AS lab_VALUENUM
        , CASE 
  			 WHEN value LIKE '%<=%' THEN '<='
             WHEN value LIKE '%<%' THEN '<'
  			 WHEN value LIKE '%>=%' THEN '>='
             WHEN value LIKE '%>%' THEN '>'
             ELSE NULL
          END as VALUE_COMPARATOR

  		-- refernce uuids (TBD: make this UUID-5 rather than random)
  		, GENERATE_UUID() as uuid_LABEVENT_ID
  		, GENERATE_UUID() as uuid_SUBJECT_ID
  		, GENERATE_UUID() as uuid_HADM_ID
  		, GENERATE_UUID() as uuid_SPECIMEN_ID
  	FROM
  		`physionet-data`.mimic_hosp.labevents lab
  		LEFT JOIN `physionet-data`.mimic_hosp.d_labitems dlab
  			ON lab.itemid = dlab.itemid
    WHERE lab.subject_id < 10001000
)

SELECT 
	uuid_LABEVENT_ID as id
    , STRUCT(
        'Observation' AS resourceType
        , uuid_LABEVENT_ID AS id
        , ARRAY(SELECT AS STRUCT
                lab_LABEVENT_ID AS value
                , 'http://fhir.mimic.mit.edu/observation-labs/identifier' AS system 
        ) AS identifier
        , 'final' AS status
        , ARRAY(SELECT AS STRUCT 
            ARRAY(SELECT AS STRUCT
                'http://terminology.hl7.org/CodeSystem/observation-category' AS system
                , 'laboratory' AS code
            ) AS coding
        ) AS category
        , STRUCT(
            ARRAY(SELECT AS STRUCT
                'http://terminology.hl7.org/CodeSystem/loinc' AS system
                , dlab_LOINC_CODE AS code
            ) AS coding
        ) AS code
        , STRUCT('Patient/' || uuid_SUBJECT_ID AS reference) AS subject
        , STRUCT('Encounter/' || uuid_HADM_ID AS reference) AS encounter
        , lab_CHARTTIME AS effectiveDateTime
        , lab_STORETIME as issued

        -- Only ONE of valueQuantity/valueString can be present in the final fhir object, so need to remove NULL values from JSON
        ,  CASE WHEN lab_VALUENUM IS NOT NULL THEN
             STRUCT(
                lab_VALUENUM AS value
                , lab_VALUEUOM AS unit
                , 'http://fhir.mimic.mit.edu/codesystem/d_labitems_uom' AS system
                , lab_VALUEUOM AS code
                , VALUE_COMPARATOR AS comparator
              ) 
          ELSE NULL END AS valueQuantity
        , CASE WHEN lab_VALUENUM IS NULL THEN 
                lab_VALUE 
          ELSE NULL
          END AS valueString
        , CASE WHEN lab_FLAG IS NOT NULL THEN   
            ARRAY(SELECT AS STRUCT 
                ARRAY(SELECT AS STRUCT
                    'http://fhir.mimic.mit.edu/CodeSystem/lab-flags' AS system
                    , lab_FLAG AS code
                ) AS coding
            )
          ELSE NULL
          END as interpretation  
        , CASE WHEN lab_COMMENTS IS NOT NULL THEN
            ARRAY(SELECT AS STRUCT 
                lab_COMMENTS as text
            )
          ELSE NULL END AS note
        , STRUCT('Specimen/' || uuid_SPECIMEN_ID AS reference) AS specimen
        , CASE WHEN lab_REF_RANGE_LOWER IS NOT NULL THEN	
              ARRAY(SELECT AS STRUCT
                    STRUCT(
                        lab_REF_RANGE_LOWER as value
                        , lab_VALUEUOM as unit
                        , 'http://fhir.mimic.mit.edu/codesystem/d_labitems_uom' as system
                        , lab_VALUEUOM as code
                    ) AS low
                 , STRUCT(
                        lab_REF_RANGE_UPPER as value
                        , lab_VALUEUOM as unit
                        , 'http://fhir.mimic.mit.edu/codesystem/d_labitems_uom' as system
                        , lab_VALUEUOM as code
                    ) AS high
              )
      	  ELSE NULL END AS referenceRange
    ) AS fhir 
FROM
	fhir_observation_labs
