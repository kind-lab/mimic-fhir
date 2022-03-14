-- Generate codesystem for icu item codes
-- Will be referenced by chartevents, datetimeevents, and outputevents

DROP TABLE IF EXISTS fhir_trm.cs_d_items;
CREATE TABLE fhir_trm.cs_d_items(
    code      VARCHAR NOT NULL,
    display   VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_d_items
SELECT 
    DISTINCT itemid AS code
    , label AS display
FROM mimic_icu.d_items di 