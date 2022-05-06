-- Transfer type class CodeSystem

DROP TABLE IF EXISTS fhir_trm.cs_transfer_type;
CREATE TABLE fhir_trm.cs_transfer_type(
    code      VARCHAR NOT NULL
);

INSERT INTO fhir_trm.cs_transfer_type(code)
VALUES('transfer encounter');
