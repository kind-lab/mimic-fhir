-- Purpose: Generate FHIR MedicationAdministration resource for each row in inputevents
-- Methods: uuid_generate_v5 --> requires uuid or text input, some inputs cast to text to fit

DROP TABLE IF EXISTS mimic_fhir.medication_administration_icu;
CREATE TABLE mimic_fhir.medication_administration_icu(
	id 		uuid PRIMARY KEY,
  	fhir 	jsonb NOT NULL 
);

WITH fhir_medication_administration_icu AS (
	SELECT
  		CAST(ie.starttime AS TIMESTAMPTZ) AS ie_STARTTIME
  		, CAST(ie.endtime AS TIMESTAMPTZ) AS ie_ENDTIME
  		, di.label AS di_LABEL
  		, ie.ordercategoryname AS ie_ORDERCATEGORYNAME
  		, ie.ordercategorydescription AS ie_ORDERCATEGORYDESCRIPTION
  		, ie.amount AS ie_AMOUNT
  		, ie.amountuom AS ie_AMOUNTUOM
  		, ie.rate AS ie_RATE
  		, ie.rateuom AS ie_RATEUOM		
  
  		-- reference uuids
  		, uuid_generate_v5(ns_medication_administration_icu.uuid, ie.stay_id || '-' || ie.orderid || '-' || ie.itemid) AS uuid_INPUTEVENT
  		, uuid_generate_v5(ns_medication.uuid, di.label) AS uuid_MEDICATION 
  		, uuid_generate_v5(ns_patient.uuid, CAST(ie.subject_id AS TEXT)) AS uuid_SUBJECT_ID
  		, uuid_generate_v5(ns_encounter_icu.uuid, CAST(ie.stay_id AS TEXT)) AS uuid_STAY_ID
  	FROM
  		mimic_icu.inputevents ie
  		INNER JOIN fhir_etl.subjects sub
  			ON ie.subject_id = sub.subject_id 
  		LEFT JOIN mimic_icu.d_items di
  			ON ie.itemid = di.itemid
  		LEFT JOIN fhir_etl.uuid_namespace ns_encounter_icu
  			ON ns_encounter_icu.name = 'EncounterICU'
  		LEFT JOIN fhir_etl.uuid_namespace ns_patient
  			ON ns_patient.name = 'Patient'
  		LEFT JOIN fhir_etl.uuid_namespace ns_medication
  			ON ns_medication.name = 'Medication'
  		LEFT JOIN fhir_etl.uuid_namespace ns_medication_administration_icu
  			ON ns_medication_administration_icu.name = 'MedicationAdministrationICU'
  			
)

INSERT INTO mimic_fhir.medication_administration_icu
SELECT 
	uuid_INPUTEVENT AS id
	, jsonb_strip_nulls(jsonb_build_object(
    	'resourceType', 'MedicationAdministration'
        , 'id', uuid_INPUTEVENT
        , 'status', 'completed'
      	, 'medicationReference', jsonb_build_object('reference', 'Medication/' || uuid_MEDICATION)
      	, 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
      	, 'context', jsonb_build_object('reference', 'Encounter/' || uuid_STAY_ID)     
       , 'effectivePeriod', 
        	CASE WHEN ie_RATE IS NOT NULL THEN
	            jsonb_build_object(	
	                'start', ie_STARTTIME
	                , 'end', ie_ENDTIME
	            )
	        ELSE NULL END
	    , 'effectiveDateTime', 
        	CASE WHEN ie_RATE IS NULL THEN ie_ENDTIME ELSE NULL END 
        	
        -- Category represent whether it is an inpatient/outpatient event	
      	, 'category', jsonb_build_object(
              'coding', jsonb_build_array(jsonb_build_object(
                  'system', 'http://fhir.mimic.mit.edu/CodeSystem/medadmin-category'  
                  , 'code', ie_ORDERCATEGORYNAME
              ))
            )
        , 'dosage', jsonb_build_object(
          	'method', jsonb_build_object(
              'coding', jsonb_build_array(jsonb_build_object(
                  'system', 'http://fhir.mimic.mit.edu/CodeSystem/medadmin-method'  
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
    )) AS fhir 
FROM
	fhir_medication_administration_icu
