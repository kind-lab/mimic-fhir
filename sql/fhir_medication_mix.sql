-- Purpose: Generate a FHIR Medication resource for each row in prescriptions.
--          Medication mixes are necessary in FHIR since MedicationAdminstrations 
--          can only reference a single Medication resource. In MIMIC there are 
--          cases when emar events deliver multiple medications, all under the 
--          same prescription
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit

WITH fhir_medication_mix AS (
    SELECT DISTINCT
        -- For prescriptions with multiple drugs prescribed, put the drugs under ingredients
        -- Order the drugs in the MAIN-BASE-ADDITIVE format 
        jsonb_agg(jsonb_build_object(
            'itemReference', 
                jsonb_build_object('reference', 'Medication/' || 
                    uuid_generate_v5(
                        ns_medication.uuid
                        , TRIM(REGEXP_REPLACE(pr.drug, '\s+', ' ', 'g'))
                    )                    
                )
        ) ORDER BY pr.drug_type DESC, pr.drug ASC) as pr_INGREDIENTS
          
        -- Drug codes will be in the format MAIN-BASE-ADDITIVE if drug type is present.
        -- Most multi drug prescriptions will have the form MAIN-BASE or MAIN-BASE-ADDITIVE.
        -- Added ordering of the drug name just to keep in consistent format, will 
        -- only really affect ADDITIVE, since MAIN and BASE are single drug entries.
        , STRING_AGG(
            TRIM(REGEXP_REPLACE(pr.drug, '\s+', ' ', 'g'))
            , '_' ORDER BY pr.drug_type DESC, pr.drug ASC
        ) AS pr_DRUG_CODE  
  
        -- reference uuid
        , uuid_generate_v5(
            ns_medication.uuid, 
            STRING_AGG(
                TRIM(REGEXP_REPLACE(pr.drug, '\s+', ' ', 'g'))
                , '_' ORDER BY pr.drug_type DESC, pr.drug ASC
            )
        ) AS uuid_DRUG
    FROM
        mimic_hosp.prescriptions pr	 
        LEFT JOIN fhir_etl.uuid_namespace ns_medication 
        ON ns_medication.name = 'Medication'
    GROUP BY 
        pr.pharmacy_id
        , ns_medication.uuid
    -- Only generate medication mixes for prescriptions with multiple drugs used. 
    -- Prescriptions with a single drug will already have their drugs mapped in 
    -- the base medication query.
    HAVING count(pr.drug) > 1 
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
        , 'code', jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-code'  
                , 'code', pr_DRUG_CODE
            ))
        )   
        , 'ingredient', pr_INGREDIENTS
    )) AS fhir 
FROM
    fhir_medication_mix
