-- Medication Route Codesystem
-- Could map to SNOMED routes - http://hl7.org/fhir/valueset-route-codes.html


DROP TABLE IF EXISTS fhir_trm.cs_medication_route;
CREATE TABLE fhir_trm.cs_medication_route(
    code      VARCHAR NOT NULL
);


WITH med_routes AS (
    SELECT DISTINCT TRIM(route) AS route FROM mimic_hosp.emar_detail 
    UNION
    SELECT DISTINCT TRIM(route) AS route FROM mimic_hosp.pharmacy
) 
INSERT INTO fhir_trm.cs_medication_route
SELECT route
FROM med_routes
WHERE route IS NOT NULL