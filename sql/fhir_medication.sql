DROP TABLE IF EXISTS mimic_fhir.medication;
CREATE TABLE mimic_fhir.medication(
	id 		uuid PRIMARY KEY,
  	fhir 	jsonb NOT NULL 
);

WITH fhir_medication_ndc AS (
	SELECT
  		pr.ndc AS pr_NDC
  		--, MIN(pr.form_rx) as pr_FORM_RX
  		, MIN(pr.drug) AS pr_DRUG
  		, NULL AS md_DRUG_ID
  
  		-- reference uuids
  		, uuid_generate_v5(ns_medication.uuid, pr.ndc) as uuid_DRUG
  	FROM
  		mimic_hosp.prescriptions pr	
  		INNER JOIN fhir_etl.subjects sub
  			ON pr.subject_id = sub.subject_id 
  		LEFT JOIN fhir_etl.uuid_namespace ns_medication
  			ON ns_medication.name = 'Medication'
  	WHERE pr.ndc != '0' AND pr.ndc IS NOT NULL AND pr.ndc != '' 
  	GROUP BY 
  		pr.ndc
  		, ns_medication.uuid
), fhir_medication_other AS (
	SELECT
  		DISTINCT pr.drug AS pr_DRUG
  		, pr.ndc AS pr_NDC
   		--, pr.form_rx as pr_FORM_RX
  		, CAST(md.drug_id AS TEXT) AS md_DRUG_ID
  
  		-- reference uuids
  		, uuid_generate_v5(ns_medication.uuid, CAST(md.drug_id AS TEXT)) AS uuid_DRUG
  	FROM
  		mimic_hosp.prescriptions pr	
  		INNER JOIN fhir_etl.subjects sub
  			ON pr.subject_id = sub.subject_id 
  		LEFT JOIN fhir_etl.map_drug_id md
  			ON pr.drug = md.drug  			
  		LEFT JOIN fhir_etl.uuid_namespace ns_medication
  			ON ns_medication.name = 'Medication'
  	WHERE 
	  	pr.ndc = '0' 
		OR pr.ndc IS NULL 
		OR pr.ndc = ''
)

INSERT INTO mimic_fhir.medication
SELECT 
	uuid_DRUG AS id
	, jsonb_strip_nulls(jsonb_build_object(
    	'resourceType', 'Medication'
        , 'id', uuid_DRUG
      	, 'code',
      		CASE WHEN pr_NDC IS NOT NULL THEN
              jsonb_build_object(
              'coding', jsonb_build_array(jsonb_build_object(
                  'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-ndc'  
                  , 'code', pr_NDC
              ))
            )	
      		ELSE 
      		  jsonb_build_object(
              'coding', jsonb_build_array(jsonb_build_object(
                  'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-drug-id'  
                  , 'code', md_DRUG_ID
              ))
            )	
      		END
      /*	, 'form', 
      		CASE WHEN pr_FORM_RX IS NOT NULL THEN
      		  jsonb_build_object(
                'coding', jsonb_build_array(jsonb_build_object(
                    'system', 'fhir.mimic-iv.ca/codesystem/medication-form'  
                    , 'code', pr_FORM_RX
                ))
              )
     		ELSE NULL
      		END */
        , 'ingredient', jsonb_build_array(jsonb_build_object(
      		'itemCodeableConcept', jsonb_build_object(
              'coding', jsonb_build_array(jsonb_build_object(
                  'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-item'  
                  , 'code', pr_DRUG
              ))
            )
          ))

    )) AS fhir 
FROM
	(
		SELECT * FROM fhir_medication_ndc
		UNION 
		SELECT * FROM fhir_medication_other
	) AS fhir_medication
