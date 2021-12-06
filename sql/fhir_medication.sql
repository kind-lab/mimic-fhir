WITH vars as (
	SELECT
  		uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Medication') as uuid_medication
), fhir_medications as (
	SELECT
  		pr.gsn as pr_GSN
  		, pr.form_rx as pr_FORM_RX
  		, pr.drug as pr_DRUG
  
  		-- refernce uuids
  		, uuid_generate_v5(uuid_medication, pr.drug) as uuid_DRUG
  	FROM
  		mimic_hosp.prescriptions pr
  		LEFT JOIN vars ON true
)

SELECT 
	uuid_DRUG as id
	, jsonb_strip_nulls(jsonb_build_array(jsonb_build_object(
    	'resourceType', 'Medication'
        , 'id', uuid_DRUG
      	, 'code',
      		CASE WHEN pr_GSN IS NOT NULL THEN
              jsonb_build_object(
              'coding', jsonb_build_array(jsonb_build_object(
                  'system', 'fhir.mimic-iv.ca/codesystem/medication-gsn'  
                  , 'code', pr_GSN
              ))
            )	
      		ELSE NULL -- THE CARDINALITY NEEDS THE CODE BUT NOT ALL GSN FILLED IN (worse for ndc)
      		END
      	, 'form', 
      		CASE WHEN pr_FORM_RX IS NOT NULL THEN
      		  jsonb_build_object(
                'coding', jsonb_build_array(jsonb_build_object(
                    'system', 'fhir.mimic-iv.ca/codesystem/medication-form'  
                    , 'code', pr_FORM_RX
                ))
              )
     		ELSE NULL
      		END
        , 'ingredient', json_build_object(
      		'itemCoedeableConcept', jsonb_build_object(
              'coding', jsonb_build_array(jsonb_build_object(
                  'system', 'fhir.mimic-iv.ca/codesystem/medication-item'  
                  , 'code', pr_DRUG
              ))
            )
          )

    ))) as fhir 
FROM
	fhir_medications
LIMIT 10
