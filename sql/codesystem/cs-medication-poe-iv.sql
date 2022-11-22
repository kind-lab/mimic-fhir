-- Medication Poe IV CodeSystem
-- IV medication requests, originating in POE

DROP TABLE IF EXISTS fhir_trm.cs_medication_poe_iv;
CREATE TABLE fhir_trm.cs_medication_poe_iv(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_medication_poe_iv
SELECT 
    DISTINCT order_type
FROM mimiciv_hosp.poe
WHERE order_type IN ('TPN', 'IV therapy')
