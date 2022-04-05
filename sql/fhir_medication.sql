-- Purpose: Generate a FHIR Medication resources for mimic medication
--          A couple different sources for medication:
--          - medication-icu
--          - medication-formulary-drug-cd
--          - medication-mix
--          - medication-name
--          - medication-poe-iv
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit

DROP TABLE IF EXISTS mimic_fhir.medication;
CREATE TABLE mimic_fhir.medication(
    id      uuid PRIMARY KEY,
    fhir    jsonb NOT NULL 
);


-- generate medication-icu
-- generate medication-formulary-drug-cd
-- generarte medication-mix
-- generate medication-name
-- generate medciation-poe-iv
----------------------------------------------------------------
----------------------- medication-icu -------------------------
----------------------------------------------------------------
WITH fhir_medication_icu AS (
    SELECT 
        CAST(di.itemid AS TEXT) AS di_ITEMID
        , di.LABEL AS di_LABEL
        
        , uuid_generate_v5(ns_medication.uuid, CAST(di.itemid AS TEXT)) AS itemid_UUID        
    FROM 
        mimic_icu.d_items di 
        LEFT JOIN fhir_etl.uuid_namespace ns_medication
            ON name = 'MedicationICU'
    WHERE 
        linksto='inputevents'
)
INSERT INTO mimic_fhir.medication
SELECT 
    itemid_UUID AS id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Medication'
        , 'id', itemid_UUID
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://fhir.mimic.mit.edu/StructureDefinition/mimic-medication'
            )
        ) 
        , 'code', jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-icu'  
                , 'code', di_ITEMID
                , 'display', di_LABEL
            ))
        )   
    )) AS fhir 
FROM
    fhir_medication_icu;

----------------------------------------------------------------
--------------- medication-formulary-drug-cd -------------------
----------------------------------------------------------------
WITH prescriptions_formulary_drug_cd AS (
    SELECT DISTINCT 
        pr.formulary_drug_cd AS formulary_drug_cd
        
        , uuid_generate_v5(ns_medication.uuid, pr.formulary_drug_cd) AS formulary_drug_cd_UUID        
    FROM 
        mimic_hosp.prescriptions pr
        LEFT JOIN fhir_etl.uuid_namespace ns_medication
            ON name = 'MedicationFormularyDrugCd'
), emar_formulary_drug_cd AS (
    SELECT DISTINCT 
        emd.product_code AS formulary_drug_cd
        
        , uuid_generate_v5(ns_medication.uuid, emd.product_code) AS formulary_drug_cd_UUID        
    FROM 
        mimic_hosp.emar_detail emd
        LEFT JOIN fhir_etl.uuid_namespace ns_medication
            ON name = 'MedicationFormularyDrugCd'
)
INSERT INTO mimic_fhir.medication
SELECT 
    formulary_drug_cd_UUID AS id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Medication'
        , 'id', formulary_drug_cd_UUID
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://fhir.mimic.mit.edu/StructureDefinition/mimic-medication'
            )
        ) 
        , 'code', jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-formulary-drug-cd'  
                , 'code', formulary_drug_cd
            ))
        )   
    )) AS fhir 
FROM
    (
        -- Keep only distinct medication from both hosp and icu tables
        SELECT formulary_drug_cd, formulary_drug_cd_UUID FROM prescriptions_formulary_drug_cd
        UNION DISTINCT
        SELECT formulary_drug_cd, formulary_drug_cd_UUID FROM emar_formulary_drug_cd
    ) AS fhir_medication_formulary_drug_cd
WHERE 
    formulary_drug_cd IS NOT NULL 
    AND formulary_drug_cd != '';


--------------------------------------------------------------
--------------------- medication-mix -------------------------
--------------------------------------------------------------

WITH medication_mix AS (
    SELECT DISTINCT 
        -- format of medication mixes will be MAIN-BASE-ADDITIVE if all drug_types are present
        -- Multiple additives are allowed, so these are ordered alphabetically 
        STRING_AGG(
            TRIM(REGEXP_REPLACE(formulary_drug_cd , '\s+', ' ', 'g'))
            , '_' ORDER BY drug_type DESC, formulary_drug_cd ASC
        ) AS medmix_code     
    FROM 
        mimic_hosp.prescriptions         
    GROUP BY 
        pharmacy_id 
    HAVING 
        COUNT(formulary_drug_cd) > 1
), fhir_medication_mix  AS (
    SELECT 
        mix.medmix_code AS mix_MEDMIX_CODE
        , uuid_generate_v5(ns_medication.uuid, mix.medmix_code) AS medmix_UUID        
    FROM 
        medication_mix mix
        LEFT JOIN fhir_etl.uuid_namespace ns_medication 
            ON ns_medication.name = 'MedicationMix'
)
INSERT INTO mimic_fhir.medication
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
        , 'code', jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-mix'  
                , 'code', mix_MEDMIX_CODE
            ))
        )   
    )) AS fhir 
FROM
    fhir_medication_mix;



--------------------------------------------------------------
--------------------- medication-name ------------------------
------------------------------------------------------------
WITH medication_name AS (
    -- prescription names are fully captured in pharmacy currently, but keeping incase this changes in future
    SELECT DISTINCT TRIM(REGEXP_REPLACE(drug, '\s+', ' ', 'g')) AS medname 
    FROM mimic_hosp.prescriptions 
    WHERE formulary_drug_cd IS NULL
    
    UNION    
    
    SELECT DISTINCT TRIM(REGEXP_REPLACE(medication, '\s+', ' ', 'g')) AS  medname 
    FROM mimic_hosp.pharmacy
    
    UNION 
    
    SELECT 
        DISTINCT TRIM(REGEXP_REPLACE(medication, '\s+', ' ', 'g')) AS medname
    FROM 
        mimic_hosp.emar_detail emd 
        LEFT JOIN mimic_hosp.emar em
            ON emd.emar_id = em.emar_id
    WHERE 
        emd.product_code IS NULL
), fhir_medication_name AS (
    SELECT
        mname.medname AS mname_MEDNAME
        , uuid_generate_v5(ns_medication.uuid, mname.medname) AS medname_UUID        
    FROM 
        medication_name mname
        LEFT JOIN fhir_etl.uuid_namespace ns_medication
            ON ns_medication.name = 'MedicationName'
    WHERE
        medname IS NOT NULL
        AND medname != ''
) 
INSERT INTO mimic_fhir.medication
SELECT 
    medname_UUID AS id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Medication'
        , 'id', medname_UUID
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://fhir.mimic.mit.edu/StructureDefinition/mimic-medication'
            )
        ) 
        , 'code', jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-name'  
                , 'code', mname_MEDNAME
            ))
        )   
    )) AS fhir 
FROM
    fhir_medication_name;

----------------------------------------------------------------
----------------------- medication-poe-iv-----------------------
----------------------------------------------------------------
-- Medication-poe-iv could be generated with just the two order_types, but generate this way in case naming changes
WITH fhir_medication_poe_iv AS (
    SELECT DISTINCT  
        poe.order_type AS poe_ORDER_TYPE
        , uuid_generate_v5(ns_medication.uuid, poe.order_type) AS order_type_UUID       
    FROM 
        mimic_hosp.poe poe
        LEFT JOIN fhir_etl.uuid_namespace ns_medication 
            ON ns_medication.name = 'MedicationPoeIv' 
    WHERE 
        order_type IN ('TPN', 'IV therapy')
) 
INSERT INTO mimic_fhir.medication
SELECT 
    order_type_UUID AS id
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'Medication'
        , 'id', order_type_UUID
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://fhir.mimic.mit.edu/StructureDefinition/mimic-medication'
            )
        ) 
        , 'code', jsonb_build_object(
            'coding', jsonb_build_array(jsonb_build_object(
                'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-poe-iv'  
                , 'code', poe_ORDER_TYPE
            ))
        )   
    )) AS fhir 
FROM
    fhir_medication_poe_iv;

