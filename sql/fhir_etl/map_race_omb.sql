DROP TABLE IF EXISTS fhir_etl.map_race_omb;
CREATE TABLE fhir_etl.map_race_omb(
    mimic_race         VARCHAR NOT NULL,
    fhir_race_omb_display   VARCHAR NOT NULL,
    fhir_race_omb_code      VARCHAR NOT NULL,
    fhir_system             VARCHAR NOT NULL
);


INSERT INTO fhir_etl.map_race_omb
    (mimic_race, fhir_race_omb_display, fhir_race_omb_code, fhir_system)
VALUES 
    ('BLACK/AFRICAN', ' Black or African American', '2054-5', 'urn:oid:2.16.840.1.113883.6.238'),
    ('MULTIPLE RACE/ETHNICITY', 'other', 'OTH', 'http://terminology.hl7.org/CodeSystem/v3-NullFlavor'),
    ('WHITE - OTHER EUROPEAN', 'White', '2106-3', 'urn:oid:2.16.840.1.113883.6.238'),
    ('WHITE - EASTERN EUROPEAN', 'White', '2106-3', 'urn:oid:2.16.840.1.113883.6.238'),
    ('ASIAN', 'Asian', '2028-9', 'urn:oid:2.16.840.1.113883.6.238'),
    ('ASIAN - ASIAN INDIAN', 'Asian', '2028-9', 'urn:oid:2.16.840.1.113883.6.238'),
    ('ASIAN - KOREAN', 'Asian', '2028-9', 'urn:oid:2.16.840.1.113883.6.238'),
    ('ASIAN - CHINESE', 'Asian', '2028-9', 'urn:oid:2.16.840.1.113883.6.238'),
    ('BLACK/AFRICAN AMERICAN', ' Black or African American', '2054-5', 'urn:oid:2.16.840.1.113883.6.238'),
    ('AMERICAN INDIAN/ALASKA NATIVE', 'American Indian or Alaska Native', '1002-5', 'urn:oid:2.16.840.1.113883.6.238'),
    ('NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER', 'Native Hawaiian or Other Pacific Islander', '2076-8', 'urn:oid:2.16.840.1.113883.6.238'),
    ('BLACK/CAPE VERDEAN', ' Black or African American', '2054-5', 'urn:oid:2.16.840.1.113883.6.238'),
    ('WHITE', 'White', '2106-3', 'urn:oid:2.16.840.1.113883.6.238'),
    ('WHITE - BRAZILIAN', 'White', '2106-3', 'urn:oid:2.16.840.1.113883.6.238'),
    ('WHITE - RUSSIAN', 'White', '2106-3', 'urn:oid:2.16.840.1.113883.6.238'),
    ('BLACK/CARIBBEAN ISLAND', ' Black or African American', '2054-5', 'urn:oid:2.16.840.1.113883.6.238'),
    ('ASIAN - SOUTH EAST ASIAN', 'Asian', '2028-9', 'urn:oid:2.16.840.1.113883.6.238'),
    ('PORTUGUESE', 'White', '2106-3', 'urn:oid:2.16.840.1.113883.6.238'),
    ('HISPANIC/LATINO - CUBAN', 'White', '2106-3', 'urn:oid:2.16.840.1.113883.6.238'),
    ('HISPANIC/LATINO - PUERTO RICAN', 'White', '2106-3', 'urn:oid:2.16.840.1.113883.6.238'),
    ('HISPANIC/LATINO - HONDURAN', 'White', '2106-3', 'urn:oid:2.16.840.1.113883.6.238'),
    ('HISPANIC/LATINO - COLUMBIAN', 'White', '2106-3', 'urn:oid:2.16.840.1.113883.6.238'),
    ('HISPANIC/LATINO - CENTRAL AMERICAN', 'White', '2106-3', 'urn:oid:2.16.840.1.113883.6.238'),
    ('HISPANIC OR LATINO', 'White', '2106-3', 'urn:oid:2.16.840.1.113883.6.238'),
    ('HISPANIC/LATINO - GUATEMALAN', 'White', '2106-3', 'urn:oid:2.16.840.1.113883.6.238'),
    ('HISPANIC/LATINO - MEXICAN', 'White', '2106-3', 'urn:oid:2.16.840.1.113883.6.238'),
    ('HISPANIC/LATINO - DOMINICAN', 'White', '2106-3', 'urn:oid:2.16.840.1.113883.6.238'),
    ('SOUTH AMERICAN', 'White', '2106-3', 'urn:oid:2.16.840.1.113883.6.238'),
    ('HISPANIC/LATINO - SALVADORAN', 'White', '2106-3', 'urn:oid:2.16.840.1.113883.6.238'),
    ('PATIENT DECLINED TO ANSWER', 'asked but unknown', 'ASKU', 'http://terminology.hl7.org/CodeSystem/v3-NullFlavor'),
    ('UNABLE TO OBTAIN', 'unknown', 'UNK', 'http://terminology.hl7.org/CodeSystem/v3-NullFlavor'),
    ('UNKNOWN', 'unknown', 'UNK', 'http://terminology.hl7.org/CodeSystem/v3-NullFlavor'),
    ('OTHER', 'unknown', 'UNK', 'http://terminology.hl7.org/CodeSystem/v3-NullFlavor');

 






