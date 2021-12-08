DROP TABLE IF EXISTS mimic_fhir.patient;
CREATE TABLE mimic_fhir.patient(
	id 		uuid PRIMARY KEY,
  	fhir 	jsonb NOT NULL 
);

WITH tb_admissions AS (
   SELECT
      pat.subject_id
      , (MIN(tfs.intime)::DATE - (pat.anchor_age ||' years')::interval)::DATE as pat_BIRTH_DATE
  	  , MIN(adm.marital_status) AS adm_MARITAL_STATUS
  	  , MIN(adm.ethnicity) AS adm_ETHNICITY
  	  , MIN(adm.language) AS adm_LANGUAGE
  FROM  
      mimic_core.patients pat
      LEFT JOIN mimic_core.transfers tfs
          ON pat.subject_id = tfs.subject_id
 	  LEFT JOIN mimic_core.admissions adm
          ON pat.subject_id = adm.subject_id
  GROUP BY 
      pat.subject_id
  	  , pat.anchor_age
), fhir_patient AS (
    SELECT
      pat.subject_id as pat_SUBJECT_ID
      , pat.gender as pat_GENDER
      , pat.dod as pat_DOD
      , 'Patient_' || pat.subject_id as pat_NAME
      , adm.pat_BIRTH_DATE
  	  , uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'Patient'), pat.subject_id::text) as UUID_patient
  	  , adm.adm_MARITAL_STATUS
  	  , adm.adm_ETHNICITY
  	  , adm.adm_LANGUAGE 	
  FROM  
      mimic_core.patients pat
      LEFT JOIN tb_admissions adm
  		  ON pat.subject_id = adm.subject_id
)

INSERT INTO mimic_fhir.patient
SELECT 
 	UUID_patient as id
    , jsonb_strip_nulls(jsonb_build_object(
      'resourceType', 'Patient'
      , 'text', 'HOW IS THIS GENERATED??'      
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
                  , 'system', 'fhir.mimic-iv.ca/patient/identifier'
        		)
      		)		
      , 'maritalStatus', adm_MARITAL_STATUS
      , 'birthDate', pat_BIRTH_DATE
      , 'deathDate', pat_DOD
      , 'extension', fn_patient_extension(adm_ETHNICITY, adm_ETHNICITY, pat_GENDER)
      , 'communication',
      	CASE WHEN adm_LANGUAGE IS NOT NULL THEN
      		jsonb_build_array(jsonb_build_object(
                'language', jsonb_build_object(
                      'coding', jsonb_build_array(jsonb_build_object(
                           'system', 'fhir.sickkids.ca/Valueset/language'
                           , 'display', adm_LANGUAGE
                        ))                        
                     )
            ))              
        ELSE NULL
        END
     , 'id', UUID_patient
     , 'managingOrganization', json_build_object(
       		'reference', 'Organization/' || uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'Organization'), 'MIMIC Hospital')  
       )
    )) as fhir
FROM 
	fhir_patient
LIMIT 10
