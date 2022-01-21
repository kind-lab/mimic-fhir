-- Purpose: Generate a FHIR Medication resources for distinct medication 
--          found across both the prescriptions and d_items tables
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit

DROP TABLE IF EXISTS mimic_fhir.medication;
CREATE TABLE mimic_fhir.medication(
	id 		uuid PRIMARY KEY,
  	fhir 	jsonb NOT NULL 
);

WITH fhir_medication_hosp AS (
	SELECT DISTINCT
  		pr.drug AS drug
  		, uuid_generate_v5(ns_medication.uuid, pr.drug) as uuid_DRUG
  	FROM
  		mimic_hosp.prescriptions pr	
  		LEFT JOIN fhir_etl.uuid_namespace ns_medication
  			ON ns_medication.name = 'Medication'
), fhir_medication_icu AS (
	SELECT DISTINCT
  		di.label AS drug
  		, uuid_generate_v5(ns_medication.uuid, di.label) as uuid_DRUG
  	FROM
  		mimic_icu.d_items di
  		LEFT JOIN fhir_etl.uuid_namespace ns_medication
  			ON ns_medication.name = 'Medication'
	WHERE 
		di.linksto = 'inputevents'
)

INSERT INTO mimic_fhir.medication
SELECT 
	uuid_DRUG AS id
	, jsonb_strip_nulls(jsonb_build_object(
    	'resourceType', 'Medication'
        , 'id', uuid_DRUG
      	, 'code',
              jsonb_build_object(
              'coding', jsonb_build_array(jsonb_build_object(
                  'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-drug'  
                  , 'code', drug
              ))
            )	
    )) AS fhir 
FROM
	(
	    -- Keep only distinct medication from both hosp and icu tables
		SELECT drug, uuid_DRUG FROM fhir_medication_hosp
		UNION DISTINCT
		SELECT drug, uuid_DRUG FROM fhir_medication_icu
	) AS fhir_medication
