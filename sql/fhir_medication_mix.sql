WITH vars as (
	SELECT
  		uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Medication') as uuid_medication
), fhir_medication_mix as (
	SELECT
  		pr.pharmacy_id as pr_PHARMACY_ID
  		--, MIN(pr.form_rx) as pr_FORM_RX
  
  		, json_agg(json_build_object(
      		'itemReference', 
          		jsonb_build_object('reference', 'Medication/' || 
                                    uuid_generate_v5(uuid_medication, CASE 
                                                                	  WHEN md.drug_id IS NOT NULL 
                                                                	  THEN md.drug_id::text 
                                                                	  ELSE pr.ndc::text END)                
              
            )
          )) as pr_INGREDIENTS
  
  		-- reference uuids
  		, uuid_generate_v5(uuid_medication, pr.pharmacy_id::text) as uuid_DRUG
  	FROM
  		mimic_hosp.prescriptions pr	 
        LEFT JOIN fhir_etl.map_drug_id md
        	ON pr.drug = md.drug
  		LEFT JOIN vars ON true
  	GROUP BY 
  		pr.pharmacy_id
  		, uuid_medication
    LIMIT 10
)

INSERT INTO mimic_fhir.medication
SELECT 
	uuid_DRUG as id
	, jsonb_strip_nulls(jsonb_build_object(
    	'resourceType', 'Medication'
        , 'id', uuid_DRUG
        , 'ingredient', pr_INGREDIENTS
    )) as fhir 
FROM
	fhir_medication_mix
LIMIT 10
