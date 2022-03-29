-- Lab priority CodeSystem
-- No mapping for priority in ObservationLab, so this will be bound to an extension

DROP TABLE IF EXISTS fhir_trm.cs_lab_priority;
CREATE TABLE fhir_trm.cs_lab_priority(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_lab_priority 
SELECT DISTINCT priority 
FROM mimic_hosp.labevents; 
