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
), fhir_medication_administration as (
	SELECT
  		em.emar_id as em_EMAR_ID
  		, em.charttime as em_CHARTTIME
        , emd.site as emd_SITE
  		, emd.route as emd_ROUTE
  		, em.event_txt as em_EVENT_TXT
  		, emd.dose_due as emd_DOSE_DUE
  		, emd.dose_due_unit as emd_DOSE_DUE_UNIT
  		, emd.infusion_rate as emd_INFUSION_RATE
  		, emd.infusion_rate_unit as emd_INFUSION_RATE_UNIT
  		
  
  		-- refernce uuids
  		, uuid_generate_v5(uuid_medication_administration, em.emar_id::text) as uuid_EMAR_ID
  		, uuid_generate_v5(uuid_medication, em.pharmacy_id::text) as uuid_MEDICATION 
  		, uuid_generate_v5(uuid_patient, em.subject_id::text) as uuid_SUBJECT_ID
  		, uuid_generate_v5(uuid_encounter, em.hadm_id::text) as uuid_HADM_ID
  	FROM
  		mimic_hosp.emar em
  		LEFT JOIN mimic_hosp.emar_detail emd
  			ON em.emar_id = emd.emar_id
  		LEFT JOIN vars ON true
 	WHERE
  		emd.parent_field_ordinal IS NULL -- just grab the dose_due information, not the split apart dose_given
  		AND em.subject_id < 10010000
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
                , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/units'
                , 'code', emd_DOSE_DUE_UNIT
              )
            , 'rateQuantity', jsonb_build_object(
              	'value', emd_INFUSION_RATE
              	, 'unit', emd_INFUSION_RATE_UNIT
                , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/units'
                , 'code', emd_INFUSION_RATE_UNIT
              )
          )
    )) as fhir 
FROM
	fhir_medication_administration
