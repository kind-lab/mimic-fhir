-- Generate unique item codes for only the datetime events
-- This is pulled from the d-items CodeSystem


DROP TABLE IF EXISTS fhir_trm.datetimeevents_d_items;
CREATE TABLE fhir_trm.datetimeevents_d_items(
    code      VARCHAR NOT NULL,
    display   VARCHAR
);

INSERT INTO fhir_trm.datetimeevents_d_items
SELECT DISTINCT 
    itemid AS code
    , LABEL AS display
FROM mimic_icu.d_items di 
WHERE linksto = 'datetimeevents'
            
