-- Generate unique item codes for only the datetime events
-- This is pulled from the d-items CodeSystem


DROP TABLE IF EXISTS fhir_trm.vs_datetimeevents_d_items;
CREATE TABLE fhir_trm.vs_datetimeevents_d_items(
    system    VARCHAR NOT NULL,
    code      VARCHAR NOT NULL,
    display   VARCHAR
);

INSERT INTO fhir_trm.vs_datetimeevents_d_items
SELECT DISTINCT 
    'http://mimic.mit.edu/fhir/CodeSystem/mimic-d-items'
    , itemid AS code
    , LABEL AS display
FROM mimic_icu.d_items di 
WHERE linksto = 'datetimeevents'
            
