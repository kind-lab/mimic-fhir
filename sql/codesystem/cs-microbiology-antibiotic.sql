-- Microbiology Antibiotic Codesystem

DROP TABLE IF EXISTS fhir_trm.cs_microbiology_antibiotic;
CREATE TABLE fhir_trm.cs_microbiology_antibiotic(
    code      VARCHAR NOT NULL,
    display   VARCHAR
);

INSERT INTO fhir_trm.cs_microbiology_antibiotic
SELECT DISTINCT 
    ab_itemid AS code
    , ab_name AS display
FROM mimiciv_hosp.microbiologyevents m 
WHERE ab_itemid IS NOT NULL