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