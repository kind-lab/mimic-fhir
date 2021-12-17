-- Creates extension for patient, but formatting slightly off
CREATE TEMP FUNCTION fn_patient_extension(race STRING, ethnicity STRING, birthsex STRING)
RETURNS STRING
AS (
    (SELECT  
    	CASE WHEN (race IS NOT NULL) or (ethnicity IS NOT NULL) or (birthsex IS NOT NULL) THEN '[' END                                                                   		
        || CASE WHEN race IS NOT NULL THEN
            TO_JSON_STRING(STRUCT(
                ARRAY(SELECT AS STRUCT
					'ombCategory' AS url
              		 , STRUCT(
                            race AS display
                            , 'urn:oid:2.16.840.1.113883.6.238' as system
                      ) as valueCoding
			    ) as extension	
			    , 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race' AS url
            ))
            ELSE NULL END 
         || CASE WHEN race IS NOT NULL AND ethnicity IS NOT NULL THEN ',' ELSE '' END
         || CASE WHEN ethnicity IS NOT NULL THEN
                TO_JSON_STRING(STRUCT(
                    ARRAY(SELECT AS STRUCT
                            'ombCategory' AS url
                            , STRUCT(
                                ethnicity AS display
                                , 'urn:oid:2.16.840.1.113883.6.238' AS system
                            ) AS valueCoding
                    ) AS extension	
                    , 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity' AS url
                ))
            ELSE NULL END  
         || CASE WHEN (race IS NOT NULL OR ethnicity IS NOT NULL) AND birthsex IS NOT NULL THEN ',' ELSE '' END
         || CASE WHEN birthsex IS NOT NULL THEN
                TO_JSON_STRING(STRUCT(
                    birthsex as valueCode	
                    , 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex' as system
                ))
            ELSE NULL
         END   
         || CASE WHEN (race IS NOT NULL) OR (ethnicity IS NOT NULL) OR (birthsex IS NOT NULL) THEN ']' END )
);

WITH tb_admissions AS (
    SELECT
        pat.subject_id
        , CAST(MIN(tfs.intime) AS DATE) AS earliest_intime
        , MIN(adm.marital_status) AS adm_MARITAL_STATUS
        , MIN(adm.ethnicity) AS adm_ETHNICITY
        , MIN(adm.language) AS adm_LANGUAGE
    FROM  
        `physionet-data`.mimic_core.patients pat
        LEFT JOIN `physionet-data`.mimic_core.transfers tfs
            ON pat.subject_id = tfs.subject_id
        LEFT JOIN `physionet-data`.mimic_core.admissions adm
            ON pat.subject_id = adm.subject_id
    WHERE pat.subject_id < 10010000
    GROUP BY 
        pat.subject_id
), fhir_patient AS (
    SELECT
      pat.subject_id as pat_SUBJECT_ID
      , pat.gender as pat_GENDER
      , pat.dod as pat_DOD
      , 'Patient_' || pat.subject_id as pat_NAME
      -- 2150-06-01 - 2148 - 96
      , DATE(
            pat.anchor_year - pat.anchor_age,
            EXTRACT(MONTH FROM adm.earliest_intime),
            EXTRACT(DAY FROM adm.earliest_intime)
      ) AS pat_BIRTH_DATE
      , GENERATE_UUID() AS uuid_patient
  	  , adm.adm_MARITAL_STATUS
  	  , adm.adm_ETHNICITY
  	  , CASE WHEN adm.adm_LANGUAGE = 'ENGLISH' THEN 'en' ELSE NULL END AS adm_LANGUAGE
  FROM  
      `physionet-data`.mimic_core.patients pat
      LEFT JOIN tb_admissions adm
  		  ON pat.subject_id = adm.subject_id
  WHERE pat.subject_id = 10012853
)
SELECT 
 	uuid_PATIENT as id
    , STRUCT(
        'Patient' AS resourceType
        , uuid_PATIENT as id
        , pat_GENDER AS gender
        , ARRAY(SELECT STRUCT(
                'official' AS use
                , pat_NAME AS family
            )) AS name
        , ARRAY(SELECT AS STRUCT
                pat_SUBJECT_ID AS value
                , 'http://fhir.mimic.mit.edu/patient/identifier' AS system
            ) AS identifier
        , adm_MARITAL_STATUS AS maritalStatus
        , pat_BIRTH_DATE AS birthDate
        , pat_DOD AS deathDate
        , fn_patient_extension(adm_ETHNICITY, adm_ETHNICITY, pat_GENDER) AS extension
        , CASE WHEN adm_LANGUAGE IS NOT NULL THEN
                ARRAY(SELECT AS STRUCT
                    STRUCT(
                        ARRAY(SELECT AS STRUCT
                            'http://hl7.org/fhir/ValueSet/languages' AS system
                            , adm_LANGUAGE AS code
                        ) AS coding
                    ) AS language
                )
            ELSE NULL END AS communication
        , STRUCT('Organization/BIDMC' AS reference) AS managingOrganization
    ) AS fhir
FROM 
	fhir_patient
