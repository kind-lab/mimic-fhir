-- Generate unique item codes for only the chartevents
-- This is pulled from the d-items CodeSystem, map to LOINC codes http://hl7.org/fhir/valueset-observation-codes.html


DROP TABLE IF EXISTS fhir_trm.cs_chartevents_d_items;
CREATE TABLE fhir_trm.cs_chartevents_d_items(
    code      VARCHAR NOT NULL,
    display   VARCHAR
);

INSERT INTO fhir_trm.cs_chartevents_d_items
SELECT DISTINCT 
    itemid AS code
    , label AS display
FROM 
    mimiciv_icu.d_items di 
WHERE linksto = 'chartevents'
            
