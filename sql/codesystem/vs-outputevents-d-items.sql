-- Generate unique itemid and labels for outputevents. 
-- Use values for CodeSystem outputevents-d-items


DROP TABLE IF EXISTS fhir_trm.vs_outputevents_d_items;
CREATE TABLE fhir_trm.vs_outputevents_d_items(
    system    VARCHAR NOT NULL, 
    code      VARCHAR NOT NULL,
    display   VARCHAR
);

INSERT INTO fhir_trm.vs_outputevents_d_items
SELECT DISTINCT 
    'http://fhir.mimic.mit.edu/CodeSystem/d-items' AS system
    , itemid AS code
    , label AS display
FROM mimic_icu.d_items 
WHERE linksto = 'outputevents'
