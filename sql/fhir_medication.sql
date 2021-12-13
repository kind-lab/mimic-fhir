/* Unique id for medication is not super straight forward. Candidates
	- GSN generic sequence number: has 757 null entries for distinct drugs
    - NDC national drug code:  has ~5000 null entries for distinct drugs
    - Drug name: there is overlap of drug name and gsn, so non unique
  Solution I think is a custom id based on gsn, where we default to gsn and if missing
  generate a code. Then this value gets converted to UUID5
  	- mimic2fhir uses rxnorm to get everything into a starndard system
  		--> first tries NDC, converts NDC to rxnorm
  		--> second tries GSN (can have multiple GSN entered), converts all GSN to rxnorm
 	 	--> third tries formulary_drug_cd, and sets if available but no system set
*/

DROP TABLE IF EXISTS mimic_fhir.medication;
CREATE TABLE mimic_fhir.medication(
	id 		uuid PRIMARY KEY,
  	fhir 	jsonb NOT NULL 
);

WITH vars as (
	SELECT
  		uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Medication') as uuid_medication
), fhir_medication_ndc as (
	SELECT
  		pr.ndc as pr_NDC
  		--, MIN(pr.form_rx) as pr_FORM_RX
  		, MIN(pr.drug) as pr_DRUG
  		, NULL as md_DRUG_ID
  
  		-- reference uuids
  		, uuid_generate_v5(uuid_medication, pr.ndc) as uuid_DRUG
  	FROM
  		mimic_hosp.prescriptions pr			
  		LEFT JOIN vars ON true
  	WHERE pr.ndc != '0' AND pr.ndc IS NOT NULL AND pr.ndc != '' 
  	GROUP BY 
  		pr.ndc
  		, uuid_medication
), fhir_medication_other as (
	SELECT
  		DISTINCT pr.drug as pr_DRUG
  		, pr.ndc as pr_NDC
   		--, pr.form_rx as pr_FORM_RX
  		, md.drug_id::text as md_DRUG_ID
  
  		-- reference uuids
  		, uuid_generate_v5(uuid_medication, md.drug_id::text) as uuid_DRUG
  	FROM
  		mimic_hosp.prescriptions pr	
  		LEFT JOIN fhir_etl.map_drug_id md
  			ON pr.drug = md.drug  			
  		LEFT JOIN vars ON true
  	WHERE pr.ndc = '0' OR pr.ndc IS NULL OR pr.ndc = ''
)

INSERT INTO mimic_fhir.medication
SELECT 
	uuid_DRUG as id
	, jsonb_strip_nulls(jsonb_build_object(
    	'resourceType', 'Medication'
        , 'id', uuid_DRUG
      	, 'code',
      		CASE WHEN pr_NDC IS NOT NULL THEN
              jsonb_build_object(
              'coding', jsonb_build_array(jsonb_build_object(
                  'system', 'fhir.mimic-iv.ca/codesystem/medication-ndc'  
                  , 'code', pr_NDC
              ))
            )	
      		ELSE 
      		  jsonb_build_object(
              'coding', jsonb_build_array(jsonb_build_object(
                  'system', 'fhir.mimic-iv.ca/codesystem/medication-drug-id'  
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
        , 'ingredient', json_build_object(
      		'itemCoedeableConcept', jsonb_build_object(
              'coding', jsonb_build_array(jsonb_build_object(
                  'system', 'fhir.mimic-iv.ca/codesystem/medication-item'  
                  , 'code', pr_DRUG
              ))
            )
          )

    )) as fhir 
FROM
	(SELECT * FROM fhir_medication_ndc
     UNION 
     SELECT * FROM fhir_medication_other) as fhir_medication
LIMIT 10
