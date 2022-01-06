DROP TABLE IF EXISTS mimic_fhir.patient;
CREATE TABLE mimic_fhir.patient(
	id 		uuid PRIMARY KEY,
  	fhir 	jsonb NOT NULL 
);

WITH tb_admissions AS (
    SELECT
        pat.subject_id
        , CAST(CAST(MIN(tfs.intime) AS DATE) - CAST(pat.anchor_age || 'years' AS INTERVAL) AS DATE) AS pat_BIRTH_DATE
        , MIN(adm.marital_status) AS adm_MARITAL_STATUS
        , MIN(adm.ethnicity) AS adm_ETHNICITY
        , MIN(adm.language) AS adm_LANGUAGE
    FROM  
        mimic_core.patients pat
        INNER JOIN fhir_etl.subjects sub
        	ON pat.subject_id = sub.subject_id 
        LEFT JOIN mimic_core.transfers tfs
            ON pat.subject_id = tfs.subject_id
        LEFT JOIN mimic_core.admissions adm
            ON pat.subject_id = adm.subject_id
    GROUP BY 
        pat.subject_id
        , pat.anchor_age
), fhir_patient AS (
    SELECT
        CAST(pat.subject_id AS TEXT) AS pat_SUBJECT_ID
        , CASE WHEN pat.gender = 'M' THEN 'male'
  			   WHEN pat.gender = 'F' THEN 'female'
  		  	   ELSE 'unknown' 
  		  END as pat_GENDER
  		, pat.gender AS pat_BIRTHSEX
        , pat.dod AS pat_DOD
        , 'Patient_' || pat.subject_id as pat_NAME
        , adm.pat_BIRTH_DATE
        , uuid_generate_v5(ns_patient.uuid, CAST(pat.subject_id AS TEXT)) AS UUID_patient
        , adm.adm_MARITAL_STATUS
        , adm.adm_ETHNICITY
        , CASE WHEN adm.adm_LANGUAGE = 'ENGLISH' THEN 'en'
  		  ELSE NULL END as adm_LANGUAGE
  		, uuid_generate_v5(ns_organization.uuid, 'Beth Israel Deaconess Medical Center') AS  UUID_organization
    FROM  
        mimic_core.patients pat
        INNER JOIN fhir_etl.subjects sub
        	ON pat.subject_id = sub.subject_id  
        LEFT JOIN tb_admissions adm
            ON pat.subject_id = adm.subject_id
  		LEFT JOIN fhir_etl.uuid_namespace ns_patient
  			ON ns_patient.name = 'Patient'
  		LEFT JOIN fhir_etl.uuid_namespace ns_organization
  			ON ns_organization.name = 'Organization'
)

INSERT INTO mimic_fhir.patient
SELECT 
 	UUID_patient AS id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Patient'
        , 'gender', pat_GENDER
        , 'name', 
                jsonb_build_array(
                    jsonb_build_object(
                    'use', 'official'
                    , 'family', pat_NAME
                    )
                )		
        , 'identifier', 
                jsonb_build_array(
                    jsonb_build_object(
                    'value', pat_SUBJECT_ID
                    , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/identifier-patient'
                    )
                )		
        , 'maritalStatus', adm_MARITAL_STATUS
        , 'birthDate', pat_BIRTH_DATE
        , 'deathDate', pat_DOD
        , 'extension', fn_patient_extension(adm_ETHNICITY, adm_ETHNICITY, pat_BIRTHSEX)
        , 'communication',
            CASE WHEN adm_LANGUAGE IS NOT NULL THEN
                jsonb_build_array(jsonb_build_object(
                    'language', jsonb_build_object(
                        'coding', jsonb_build_array(jsonb_build_object(
                            'system', 'urn:ietf:bcp:47'
                            , 'code', adm_LANGUAGE
                            ))                        
                        )
                ))              
            ELSE NULL
            END
        , 'id', UUID_patient
        , 'managingOrganization', json_build_object(
                'reference', 'Organization/' || UUID_organization
        )
    )) AS fhir
FROM 
	fhir_patient
