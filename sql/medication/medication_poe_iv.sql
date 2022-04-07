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
