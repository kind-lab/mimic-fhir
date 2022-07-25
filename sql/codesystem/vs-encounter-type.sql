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
    ('http://hl7.org/fhir/us/core/ValueSet/us-core-encounter-type', '*', '*') -- the base valueset to be extended 
    , ('http://terminology.hl7.org/CodeSystem/HCPCS', '*', '*')
    , ('http://snomed.info/sct', '453701000124103', 'In-person encounter (procedure)')
