-- Microbiology Interpretation Codesystem

DROP TABLE IF EXISTS fhir_trm.microbiology_interpretation;
CREATE TABLE fhir_trm.microbiology_interpretation(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.microbiology_interpretation
SELECT DISTINCT interpretation 
FROM mimic_hosp.microbiologyevents m 
WHERE interpretation IS NOT NULL