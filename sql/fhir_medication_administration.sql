-- Purpose: Generate a FHIR MedicatioAdministration resource for each row in emar
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit

DROP TABLE IF EXISTS mimic_fhir.medication_administration;
CREATE TABLE mimic_fhir.medication_administration(
    id          uuid PRIMARY KEY,
    patient_id  uuid NOT NULL,
    fhir        jsonb NOT NULL 
);


-- Generate the drug code for all prescriptions
-- Three primary sources for medication in emar
--    1) emar_detail.product_code -> primary code
--    2) emar.medication -> when no product code
--    3) poe.order_type -> this is for IV fluids
--    4) if nothing is present then store as Unknown medication
WITH prescriptions AS (
    SELECT DISTINCT pharmacy_id 
    FROM mimic_hosp.prescriptions 
), fhir_medication_administration AS (
    SELECT
        emd.emar_id || '-' || emd.parent_field_ordinal AS em_MEDADMIN_ID
        , CAST(em.charttime AS TIMESTAMPTZ) AS em_CHARTTIME
  		
        -- FHIR VALIDATOR does NOT accept leading/trailing white spaces, so trim values
        , TRIM(REGEXP_REPLACE(emd.site, '\s+', ' ', 'g')) AS emd_SITE
        , TRIM(emd.route) AS emd_ROUTE
        , TRIM(em.event_txt) AS em_EVENT_TXT 
        
        -- dose given, grab numeric value if present
        , CASE 
            WHEN emd.dose_given IN ('N', 'INI') THEN 
                CAST(emd.product_amount_given AS DECIMAL)
            WHEN emd.dose_given ~ '^[0-9\.]+$' THEN -- ALL NUMERIC
                CAST(emd.dose_given AS DECIMAL)
            ELSE NULL -- accounts FOR 46,000 VALUES WITH FREE text      
        END AS emd_DOSE_GIVEN
        
        -- FHIR VALIDATOR fails IF ANY leading/trailing white space present
        , CASE 
            WHEN emd.dose_given IN ('N', 'INI') THEN 
                TRIM(emd.product_unit)
            WHEN emd.dose_given ~ '^[0-9\.]+$' THEN -- ALL NUMERIC
                TRIM(emd.dose_given_unit)
            ELSE NULL -- accounts FOR 46,000 VALUES WITH FREE text      
        END AS emd_DOSE_GIVEN_UNIT
        
        -- store free text dose_given in text
        , CASE 
            WHEN emd.dose_given IN ('N', 'INI') THEN 
                NULL
            WHEN emd.dose_given ~ '^[0-9\.]+$' THEN -- ALL NUMERIC
                '1'
            ELSE CONCAT('dose_given: ', emd.dose_given, emd.dose_given_unit) -- accounts FOR 46,000 VALUES WITH FREE text      
        END AS emd_DOSE_GIVEN_TEXT
        
        , emd.infusion_rate AS emd_INFUSION_RATE
        , TRIM(emd.infusion_rate_unit) AS emd_INFUSION_RATE_UNIT -- FHIR VALIDATOR fails IF ANY leading/trailing white space present
  
  		-- reference uuids
        , uuid_generate_v5(
            ns_medication_administration.uuid, 
            emd.emar_id || '-' || emd.parent_field_ordinal
        ) AS uuid_MEDADMIN
        
        , uuid_generate_v5(ns_patient.uuid, CAST(em.subject_id AS TEXT)) AS uuid_SUBJECT_ID
        , uuid_generate_v5(ns_encounter.uuid, CAST(em.hadm_id AS TEXT)) AS uuid_HADM_ID
        
        , CASE 
            WHEN pr.pharmacy_id IS NOT NULL THEN
                uuid_generate_v5(ns_medication_request.uuid, CAST(pr.pharmacy_id AS TEXT))
            ELSE
                uuid_generate_v5(ns_medication_request.uuid, poe.poe_id)
        END AS uuid_MEDICATION_REQUEST
        
        
        , CASE 
            WHEN emd.product_code IS NOT NULL THEN 
                uuid_generate_v5(ns_medication_cd.uuid, emd.product_code)
            WHEN em.medication IS NOT NULL THEN
                uuid_generate_v5(ns_medication_name.uuid, TRIM(REGEXP_REPLACE(em.medication, '\s+', ' ', 'g')))
            WHEN poe.order_type IN ('TPN', 'IV therapy') THEN
                uuid_generate_v5(ns_medication_poe.uuid, poe.order_type)
        ELSE NULL END AS uuid_MEDICATION
            
        
    FROM
        mimic_hosp.emar_detail emd
        INNER JOIN fhir_etl.subjects sub
            ON emd.subject_id = sub.subject_id 
        LEFT JOIN mimic_hosp.emar em
            ON emd.emar_id = em.emar_id
        LEFT JOIN mimic_hosp.poe poe
            ON em.poe_id = poe.poe_id 
        LEFT JOIN prescriptions pr
            ON emd.pharmacy_id = pr.pharmacy_id
        LEFT JOIN fhir_etl.uuid_namespace ns_encounter
            ON ns_encounter.name = 'Encounter'
        LEFT JOIN fhir_etl.uuid_namespace ns_patient
            ON ns_patient.name = 'Patient'
        LEFT JOIN fhir_etl.uuid_namespace ns_medication_cd
            ON ns_medication_cd.name = 'MedicationFormularyDrugCd'
        LEFT JOIN fhir_etl.uuid_namespace ns_medication_name
            ON ns_medication_name.name = 'MedicationName'
        LEFT JOIN fhir_etl.uuid_namespace ns_medication_poe
            ON ns_medication_poe.name = 'MedicationPoeIv'
        LEFT JOIN fhir_etl.uuid_namespace ns_medication_request
            ON ns_medication_request.name = 'MedicationRequest'
        LEFT JOIN fhir_etl.uuid_namespace ns_medication_administration
            ON ns_medication_administration.name = 'MedicationAdministration'
    WHERE
        -- Select each individual dose given in the emar_detail row, skipping the summary row
        emd.parent_field_ordinal IS NOT NULL 
        AND (pr.pharmacy_id IS NOT NULL
            OR em.medication IS NOT NULL 
            OR poe.order_type IN ('TPN', 'IV therapy'))
        
        
)

INSERT INTO mimic_fhir.medication_administration
SELECT 
    uuid_MEDADMIN as id
    , uuid_SUBJECT_ID AS patient_id 
    , jsonb_strip_nulls(jsonb_build_object(
        'resourceType', 'MedicationAdministration'
        , 'id', uuid_MEDADMIN
        , 'meta', jsonb_build_object(
            'profile', jsonb_build_array(
                'http://fhir.mimic.mit.edu/StructureDefinition/mimic-medication-administration'
            )
        ) 
        , 'identifier', jsonb_build_array(jsonb_build_object(
            'value', em_MEDADMIN_ID
            , 'system', 'http://fhir.mimic.mit.edu/identifier/medication-administration'	
            , 'type', jsonb_build_object(
                'coding', jsonb_build_array(jsonb_build_object(
                    'code', 'MEDHOSP'
                    , 'display', 'ICU medication administration'
                    , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/identifier-type'
                ))
            )
        ))	
        , 'status', 'completed' -- All medication adminstrations considered complete
        , 'medicationReference', 
            CASE WHEN uuid_MEDICATION IS NOT NULL THEN
                jsonb_build_object('reference', 'Medication/' || uuid_MEDICATION)
            ELSE NULL END
        , 'medicationCodeableConcept',
            CASE WHEN uuid_MEDICATION IS NULL THEN
                jsonb_build_object(
                    'coding', jsonb_build_array(jsonb_build_object(
                        'system', 'http://terminology.hl7.org/CodeSystem/v3-NullFlavor'  
                        , 'code', 'UNK'
                        , 'display', 'unknown'
                    ))
                )
            ELSE NULL END        
        , 'request', jsonb_build_object('reference', 'MedicationRequest/' || uuid_MEDICATION_REQUEST)
        , 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
        , 'context', 
            CASE WHEN uuid_HADM_ID IS NOT NULL
                THEN jsonb_build_object('reference', 'Encounter/' || uuid_HADM_ID) 
            ELSE NULL END
        , 'effectiveDateTime', em_CHARTTIME
        , 'dosage', jsonb_build_object(
            'text', emd_DOSE_GIVEN_TEXT
            , 'site', 
                CASE WHEN emd_SITE IS NOT NULL THEN 
                    jsonb_build_object(
                        'coding', jsonb_build_array(jsonb_build_object(
                            'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-site'  
                            , 'code', emd_SITE
                        ))
                    )
                ELSE NULL END              
            , 'route', 
                CASE WHEN emd_ROUTE IS NOT NULL THEN 
                    jsonb_build_object(
                        'coding', jsonb_build_array(jsonb_build_object(
                            'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-route'  
                            , 'code', emd_ROUTE
                        ))
                    )
                ELSE NULL END
            , 'method', jsonb_build_object(
                'coding', jsonb_build_array(jsonb_build_object(
                    'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-method'  
                    , 'code', em_EVENT_TXT
                ))
            )
            , 'dose', 
                CASE WHEN emd_DOSE_GIVEN IS NOT NULL THEN 
                    jsonb_build_object(
                        'value', emd_DOSE_GIVEN
                        , 'unit', emd_DOSE_GIVEN_UNIT
                        , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/units'
                        , 'code', emd_DOSE_GIVEN_UNIT
                    )
                ELSE NULL END
            , 'rateQuantity', 
                CASE WHEN emd_INFUSION_RATE IS NOT NULL THEN 
                    jsonb_build_object(
                        'value', emd_INFUSION_RATE
                        , 'unit', emd_INFUSION_RATE_UNIT
                        , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/units'
                        , 'code', emd_INFUSION_RATE_UNIT
                    )   
                ELSE NULL END
        )
    )) as fhir 
FROM
    fhir_medication_administration
