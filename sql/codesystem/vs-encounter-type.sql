-- Encounter Type Valueset
-- Combine the mimic hcpcs-cd codesystem and the default code from http://snomed.info/sct#453701000124103

DROP TABLE IF EXISTS fhir_trm.vs_encounter_type;
CREATE TABLE fhir_trm.vs_encounter_type(
    system      VARCHAR NOT NULL,
    code        VARCHAR NOT NULL,
    display     VARCHAR NOT NULL
    
);

INSERT INTO fhir_trm.vs_encounter_type (system, code, display)
VALUES
    ('http://fhir.mimic.mit.edu/CodeSystem/hcpcs-cd', '*', '*')
    , ('http://snomed.info/sct', '453701000124103', 'In-person encounter (procedure)')
