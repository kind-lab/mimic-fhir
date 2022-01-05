DROP TABLE IF EXISTS mimic_fhir.medication_administration;
CREATE TABLE mimic_fhir.medication_administration(
	id 		uuid PRIMARY KEY,
  	fhir 	jsonb NOT NULL 
);

WITH vars as (
	SELECT
  		uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Encounter') as uuid_encounter
  		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Patient') as uuid_patient
 		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Medication') as uuid_medication
  		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'MedicationAdministration') as uuid_medication_administration
), fhir_medication_administration AS (
	SELECT
  		em.emar_id AS em_EMAR_ID
  		, CAST(em.charttime AS TIMESTAMPTZ) AS em_CHARTTIME
        , emd.site AS emd_SITE
  		, emd.route AS emd_ROUTE
  		, em.event_txt AS em_EVENT_TXT
  		, emd.dose_due AS emd_DOSE_DUE
  		, emd.dose_due_unit AS emd_DOSE_DUE_UNIT
  		, emd.infusion_rate AS emd_INFUSION_RATE
  		, emd.infusion_rate_unit AS emd_INFUSION_RATE_UNIT
  		
  
  		-- refernce uuids
  		, uuid_generate_v5(uuid_medication_administration, CAST(em.emar_id AS TEXT)) AS uuid_EMAR_ID
  		, uuid_generate_v5(uuid_medication, CAST(em.pharmacy_id as TEXT)) AS uuid_MEDICATION 
  		, uuid_generate_v5(uuid_patient, CAST(em.subject_id AS TEXT)) AS uuid_SUBJECT_ID
  		, uuid_generate_v5(uuid_encounter, CAST(em.hadm_id AS TEXT)) AS uuid_HADM_ID
  	FROM
  		mimic_hosp.emar em
  		INNER JOIN fhir_etl.subjects sub
  			ON em.subject_id = sub.subject_id 
  		LEFT JOIN mimic_hosp.emar_detail emd
  			ON em.emar_id = emd.emar_id
  		LEFT JOIN vars ON true
 	WHERE
  		emd.parent_field_ordinal IS NULL -- just grab the dose_due information, not the split apart dose_given
)

INSERT INTO mimic_fhir.medication_administration
SELECT 
	uuid_EMAR_ID as id
	, jsonb_strip_nulls(jsonb_build_object(
    	'resourceType', 'MedicationAdministration'
        , 'id', uuid_EMAR_ID
      	, 'identifier', 
      		jsonb_build_array(
        		jsonb_build_object(
                  'value', em_EMAR_ID
                  , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/identifier-emar-id'
        		)
      		)	
        , 'status', 'completed'
      	, 'medicationReference', jsonb_build_object('reference', 'Medication/' || uuid_MEDICATION)
      	, 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
      	, 'context', 
      		CASE WHEN uuid_HADM_ID IS NOT NULL
      		  THEN jsonb_build_object('reference', 'Encounter/' || uuid_HADM_ID) 
      		  ELSE NULL
      		END
        , 'effectiveDateTime', em_CHARTTIME
        , 'dosage', jsonb_build_object(
          	'site', jsonb_build_object(
              'coding', jsonb_build_array(jsonb_build_object(
                  'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-site'  
                  , 'code', emd_SITE
              ))
            )
          	, 'route', jsonb_build_object(
              'coding', jsonb_build_array(jsonb_build_object(
                  'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-route'  
                  , 'code', emd_ROUTE
              ))
            )
          	, 'method', jsonb_build_object(
              'coding', jsonb_build_array(jsonb_build_object(
                  'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-method'  
                  , 'code', em_EVENT_TXT
              ))
            )
          	, 'dose', jsonb_build_object(
              	'value', emd_DOSE_DUE
              	, 'unit', emd_DOSE_DUE_UNIT
                , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/med-units'
                , 'code', emd_DOSE_DUE_UNIT
              )
            , 'rateQuantity', jsonb_build_object(
              	'value', emd_INFUSION_RATE
              	, 'unit', emd_INFUSION_RATE_UNIT
                , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/md-units'
                , 'code', emd_INFUSION_RATE_UNIT
              )
          )
    )) as fhir 
FROM
	fhir_medication_administration
