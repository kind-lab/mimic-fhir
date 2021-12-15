DROP TABLE IF EXISTS mimic_fhir.medication_request;
CREATE TABLE mimic_fhir.medication_request(
	id 		uuid PRIMARY KEY,
  	fhir 	jsonb NOT NULL 
);

WITH vars as (
	SELECT
  		uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Encounter') as uuid_encounter
  		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Patient') as uuid_patient
 		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'Medication') as uuid_medication
  		, uuid_generate_v5(uuid_generate_v5(uuid_ns_oid(), 'MIMIC-IV'), 'MedicationRequest') as uuid_medication_request
), fhir_medication_request as (
	SELECT
  		ph.pharmacy_id as ph_PHARMACY_ID
  		, ph.status as ph_STATUS
  		, ph.route as ph_ROUTE
  		, ph.starttime as ph_STARTTIME
  		, ph.stoptime as ph_STOPTIME
  		
  
  		-- refernce uuids
  		, uuid_generate_v5(uuid_medication_request, ph.pharmacy_id::text) as uuid_MEDICATION_REQUEST 
  		, uuid_generate_v5(uuid_medication, ph.pharmacy_id::text) as uuid_MEDICATION 
  		, uuid_generate_v5(uuid_patient, ph.subject_id::text) as uuid_SUBJECT_ID
  		, uuid_generate_v5(uuid_encounter, ph.hadm_id::text) as uuid_HADM_ID
  	FROM
  		mimic_hosp.pharmacy ph
  		LEFT JOIN vars ON true  		

) 

INSERT INTO mimic_fhir.medication_request
SELECT 
	uuid_MEDICATION_REQUEST as id
	, jsonb_strip_nulls(jsonb_build_object(
    	'resourceType', 'MedicationRequest'
        , 'id', uuid_MEDICATION_REQUEST
      	, 'identifier', 
      		jsonb_build_array(
        		jsonb_build_object(
                  'value', ph_PHARMACY_ID
                  , 'system', 'http://fhir.mimic.mit.edu/CodeSystem/identifier-medication-request'
        		)
      		)	
        , 'status', ph_STATUS
      	, 'intent', 'order'
      	, 'medicationReference', jsonb_build_object('reference', 'Medication/' || uuid_MEDICATION)
      	, 'subject', jsonb_build_object('reference', 'Patient/' || uuid_SUBJECT_ID)
      	, 'encounter', 
      		CASE WHEN uuid_HADM_ID IS NOT NULL
      		  THEN jsonb_build_object('reference', 'Encounter/' || uuid_HADM_ID) 
      		  ELSE NULL
      		END
        , 'dosageInstruction', jsonb_build_array(jsonb_build_object(
        	'route', jsonb_build_object(
              'coding', jsonb_build_array(jsonb_build_object(
                  'system', 'http://fhir.mimic.mit.edu/CodeSystem/medication-route'  
                  , 'code', ph_ROUTE
              ))
            )
        ))
        , 'dispenseRequest', jsonb_build_object(
        	 'validityPeriod', jsonb_build_object(
               	'start', ph_STARTTIME
               	, 'end', ph_STOPTIME
              )
        )      
    )) as fhir  
FROM
	fhir_medication_request
LIMIT 10
