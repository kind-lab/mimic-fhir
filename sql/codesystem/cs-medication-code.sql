-- Generate the medication codes from the mimic_fhir.medication table.
-- Could generate the medication codes from source but multiple big steps 
-- that were done on the way to creating mimic_fhir.medication 
-- Steps to create mimic_fhir.medication table
--      1. Get distinct individual medication from prescriptions
--      2. Get distinct medication from d_items for inputevents
--      3. UNION results from 1 and 2
--      4. Get distinct medication mixes from prescriptions (prescriptions with 2+ meds)


-- ->> operator converts the json value to text, if just extract the path 
-- then quotation marks are left over (even if you cast to text after)
SELECT jsonb_extract_path(fhir, 'code', 'coding', '0') ->> 'code' FROM mimic_fhir.medication m 

