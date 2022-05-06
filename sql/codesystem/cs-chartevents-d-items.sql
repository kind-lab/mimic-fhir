-- Generate unique item codes for only the chartevents
-- This is pulled from the d-items CodeSystem


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
    mimic_icu.d_items di 
WHERE linksto = 'chartevents'
            
