DROP TABLE IF EXISTS mimic_fhir.medadmin_icu;
CREATE TABLE mimic_fhir.medadmin_icu(
	id 		uuid PRIMARY KEY,
  	fhir 	jsonb NOT NULL 
);

WITH vars as (
	SELECT
  		uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'EncounterICU') as uuid_encounter_icu
  		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Patient') as uuid_patient
 		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Medication') as uuid_medication
  		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'MedicationAdministrationICU') as uuid_medication_administration_icu
), fhir_medication_administration_icu as (
	SELECT
  		ie.starttime::TIMESTAMPTZ as ie_STARTTIME
  		, ie.endtime::TIMESTAMPTZ as ie_ENDTIME
  		, di.label as di_LABEL
  		, ie.ordercategoryname as ie_ORDERCATEGORYNAME
  		, ie.ordercategoryname as ie_ORDERCATEGORYDESCRIPTION
  		, ie.amount as ie_AMOUNT
  		, ie.amountuom as ie_AMOUNTUOM
  		, ie.rate as ie_RATE
  		, ie.rateuom as ie_RATEUOM		
  
  		-- reference uuids
  		, uuid_generate_v5(uuid_medication_administration_icu, ie.stay_id || '-' || ie.orderid || '-' || ie.itemid) as uuid_INPUTEVENT
  		, NULL as uuid_MEDICATION -- needs to be mapped back to pharmacy/prescriptions OR create medication resources based on orderids
  		--, uuid_generate_v5(uuid_medication, em.pharmacy_id::text) as uuid_MEDICATION 
  		, uuid_generate_v5(uuid_patient, ie.subject_id::text) as uuid_SUBJECT_ID
  		, uuid_generate_v5(uuid_encounter_icu, ie.stay_id::text) as uuid_STAY_ID
  	FROM
  		mimic_icu.inputevents ie
  		LEFT JOIN mimic_icu.d_items di
  			ON ie.itemid = di.itemid
  		LEFT JOIN vars ON true
    WHERE
  		ie.subject_id < 10010000
)

INSERT INTO mimic_fhir.medadmin_icu
SELECT 
	uuid_INPUTEVENT as id
	, jsonb_strip_nulls(jsonb_build_object(
    	'resourceType', 'MedicationAdministration'
        , 'id', uuid_INPUTEVENT
        , 'status', 'completed'
      	, 'medicationReference', NULL -- jsonb_build_object('reference', 'Medication/' || uuid_MEDICATION)
      	, 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
      	, 'context', jsonb_build_object('reference', 'Encounter/' || uuid_STAY_ID)     
        , 'effectivePeriod', 
            jsonb_build_object(	
                'start', ie_STARTTIME
                , 'end', ie_ENDTIME
            )
      	, 'category', jsonb_build_object(
              'coding', jsonb_build_array(jsonb_build_object(
                  'system', 'http://fhir.mimic.mit.edu/CodeSystem/medadmin-category'  
                  , 'code', ie_ORDERCATEGORYNAME
              ))
            )
        , 'dosage', jsonb_build_object(
          	'method', jsonb_build_object(
              'coding', jsonb_build_array(jsonb_build_object(
                  'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-method'  
                  , 'code', ie_ORDERCATEGORYDESCRIPTION
              ))
            )
          	, 'dose', jsonb_build_object(
              	'value', ie_AMOUNT
              	, 'unit', ie_AMOUNTUOM
                , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/units'
                , 'code', ie_AMOUNTUOM
              )
            , 'rateQuantity', 
          		CASE WHEN ie_RATE IS NOT NULL THEN
          			jsonb_build_object(
                      'value', ie_RATE
                      , 'unit', ie_RATEUOM
                      , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/units'
                      , 'code', ie_RATEUOM
              		)
         		ELSE NULL
          		END
          )
    )) as fhir 
FROM
	fhir_medication_administration_icu
