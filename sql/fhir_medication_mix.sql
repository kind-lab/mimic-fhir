-- Purpose: Generate a FHIR Medication resource for each row in prescriptions.
--          Medication mixes are necessary in FHIR since MedicationAdminstrations 
--          can only reference a single Medication resource. In MIMIC there are 
--          cases when emar events deliver multiple medications, all under the 
--          same prescription
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit

WITH fhir_medication_mix AS (
	SELECT
  		pr.pharmacy_id AS pr_PHARMACY_ID
  
  		-- Group all medications under the same prescription
  		, json_agg(json_build_object(
      		'itemReference', 
          		jsonb_build_object('reference', 'Medication/' || 
                    uuid_generate_v5(ns_medication.uuid, pr.drug)                    
                )
          )) as pr_INGREDIENTS
  
  		-- reference uuids
  		, uuid_generate_v5(ns_medication.uuid, CAST(pr.pharmacy_id AS TEXT)) AS uuid_DRUG
  	FROM
  		mimic_hosp.prescriptions pr	 
  		INNER JOIN fhir_etl.subjects sub
  			ON pr.subject_id = sub.subject_id 
  		LEFT JOIN fhir_etl.uuid_namespace ns_medication 
  			ON ns_medication.name = 'Medication'
  	GROUP BY 
  		pr.pharmacy_id
  		, ns_medication.uuid
)

INSERT INTO mimic_fhir.medication
SELECT 
	uuid_DRUG AS id
	, jsonb_strip_nulls(jsonb_build_object(
    	'resourceType', 'Medication'
        , 'id', uuid_DRUG
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://fhir.mimic.mit.edu/StructureDefinition/mimic-medication'
            )
         ) 
        , 'ingredient', pr_INGREDIENTS
    )) AS fhir 
FROM
	fhir_medication_mix
