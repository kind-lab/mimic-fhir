-- Microbiology Interpretation Codesystem

DROP TABLE IF EXISTS fhir_trm.cs_microbiology_interpretation;
CREATE TABLE fhir_trm.cs_microbiology_interpretation(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_microbiology_interpretation
SELECT DISTINCT interpretation 
FROM mimiciv_hosp.microbiologyevents m 
WHERE interpretation IS NOT NULL