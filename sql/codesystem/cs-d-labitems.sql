-- D Lab Items CodeSystem
-- Convert lab items to LOINC in concept mapping step


DROP TABLE IF EXISTS fhir_trm.d_labitems;
CREATE TABLE fhir_trm.d_labitems(
    code      VARCHAR NOT NULL,
    display   VARCHAR --Can have NULL display IF itemid still present
);

INSERT INTO fhir_trm.d_labitems
SELECT 
    itemid AS code
    , label AS display
FROM mimic_hosp.d_labitems 