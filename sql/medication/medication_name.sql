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