-- Purpose: Generate a FHIR Medication mix from prescriptions table
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit
-- No medication.code set since there is no one code that encapsulates the medication. Medicaiton are stored in ingredients

DROP TABLE IF EXISTS mimic_fhir.medication_mix;
CREATE TABLE mimic_fhir.medication_mix(
    id          uuid PRIMARY KEY,
    fhir        jsonb NOT NULL 
);


WITH medication_identifier AS (
    SELECT 
       (    
            drug
            || CASE WHEN (formulary_drug_cd IS NOT NULL) AND (formulary_drug_cd != '') 
                    THEN '--' || formulary_drug_cd ELSE '' END    
            || CASE WHEN (ndc IS NOT NULL) AND (ndc !='0') AND (ndc != '') 
                    THEN '--' || ndc ELSE '' END
        ) AS med_id
        , pharmacy_id
        , drug
        , drug_type
    FROM 
        mimic_hosp.prescriptions pr
), medication_mix AS (
    SELECT DISTINCT 
        -- For prescriptions with multiple drugs prescribed, put the drugs under ingredients
        -- Order the drugs in the MAIN-BASE-ADDITIVE format 
        jsonb_agg(jsonb_build_object(
            'itemReference', 
                jsonb_build_object('reference', 'Medication/' || 
                    uuid_generate_v5(ns_medication.uuid, mid.med_id)                    
                )
        ) ORDER BY pr.drug_type DESC, pr.drug  ASC) as pr_INGREDIENTS
    
    
    
        -- format of medication mixes will be MAIN-BASE-ADDITIVE if all drug_types are present
        -- Multiple additives are allowed, so these are ordered alphabetically 
        , STRING_AGG(mid.med_id, '_' ORDER BY pr.drug_type DESC, pr.drug ASC) AS medmix_id   
    FROM 
        mimic_hosp.prescriptions pr
        LEFT JOIN medication_identifier mid
            ON pr.pharmacy_id = mid.pharmacy_id
            AND pr.drug = mid.drug
            AND pr.drug_type = mid.drug_type
        LEFT JOIN fhir_etl.uuid_namespace ns_medication 
            ON ns_medication.name = 'MedicationPrescriptions'
    GROUP BY 
        pr.pharmacy_id 
    HAVING 
        COUNT(mid.med_id) > 1
), fhir_medication_mix  AS (
    SELECT 
        uuid_generate_v5(ns_medication.uuid, mix.medmix_id) AS medmix_UUID      
        , pr_INGREDIENTS
    FROM 
        medication_mix mix
        LEFT JOIN fhir_etl.uuid_namespace ns_medication 
            ON ns_medication.name = 'MedicationPrescriptions'
)
INSERT INTO mimic_fhir.medication_mix
SELECT 
    medmix_UUID AS id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Medication'
        , 'id', medmix_UUID
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://fhir.mimic.mit.edu/StructureDefinition/mimic-medication'
            )
        ) 
        , 'ingredient', pr_INGREDIENTS
    )) AS fhir 
FROM
    fhir_medication_mix;