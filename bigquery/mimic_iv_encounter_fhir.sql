WITH tb_diagnoses as (
    SELECT 
  		adm.hadm_id 
        , STRUCT(
            array_agg(
                STRUCT(diag.icd_code as condition) -- needs to be updated to UUID5 for condition
            ) as    diagnosis
        ) as fhir_DIAGNOSES
    FROM
		`physionet-data`.mimic_core.admissions adm
		LEFT JOIN `physionet-data`.mimic_hosp.diagnoses_icd diag
			ON adm.hadm_id = diag.hadm_id
    WHERE adm.subject_id < 10001000
    GROUP BY
        adm.hadm_id
)

, fhir_encounter as (
	SELECT 
  		adm.hadm_id as adm_HADM_ID			
  		, adm.admission_type as adm_ADMISSION_TYPE
  		, adm.admittime as adm_ADMITTIME
  		, adm.dischtime as adm_DISCHTIME
  		, adm.admission_location as adm_ADMISSION_LOCATION  		
  		, adm.discharge_location as adm_DISCHARGE_LOCATION  		
  		, diag.fhir_DIAGNOSES as fhir_DIAGNOSES
  	
  		-- reference uuids
  		, GENERATE_UUID() as uuid_HADM_ID
  		, GENERATE_UUID() as uuid_SUBJECT_ID
  		, GENERATE_UUID() as uuid_ORG
 	FROM 
  		`physionet-data`.mimic_core.admissions adm
  		LEFT JOIN tb_diagnoses diag
  			ON adm.hadm_id = diag.hadm_id
 	WHERE
  		adm.subject_id < 10001000
)

SELECT  
	uuid_HADM_ID as id
    , STRUCT(
      	 'Encounter' as resourceType
         , uuid_HADM_ID as id
         , ARRAY(SELECT AS STRUCT
                adm_HADM_ID as value
                , 'http://fhir.mimic.mit.edu/encounter/identifier' as system        		
      		) as identifier	
      	 , 'finished' as status
         , STRUCT(
                'fhir.mimic-iv.ca/valuest/admission-class' as system
                , adm_ADMISSION_TYPE as display
           ) as class
         , ARRAY(SELECT AS STRUCT
         		ARRAY(SELECT AS STRUCT
                	'http://fhir.mimic.mit.edu/ValueSet/admission-type' as system
                    , adm_ADMISSION_TYPE as display
                ) as coding
           ) as type
      	 , STRUCT('Patient/' || uuid_SUBJECT_ID as reference) as subject
         , STRUCT(
         	  adm_ADMITTIME as start
              , adm_DISCHTIME as `end`
         ) as period
         , STRUCT(
            CASE WHEN adm_ADMISSION_LOCATION IS NOT NULL
                THEN STRUCT(
                    ARRAY(SELECT AS STRUCT
                        'http://fhir.mimic.mit.edu/ValueSet/admit-source' as system
                        , adm_ADMISSION_LOCATION as display
                    ) as coding             
                )
                ELSE NULL
                END as admitSource
           , CASE WHEN adm_DISCHARGE_LOCATION IS NOT NULL
           	   THEN STRUCT(
                  ARRAY(SELECT AS STRUCT
                      'http://fhir.mimic.mit.edu/ValueSet/discharge-dispostion' as system
                      , adm_DISCHARGE_LOCATION as display
                  ) as coding               
            	)
           	   ELSE NULL
           	   END as dischargeDisposition
         ) as hospitalization       
         , fhir_DIAGNOSES as diangosis
         , STRUCT('Organization/BIDMC' AS reference) AS  serviceProvider	 		
	) as fhir
FROM 
	fhir_encounter 
