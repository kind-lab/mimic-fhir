CREATE OR REPLACE FUNCTION fhir_etl.fn_create_table_patient_dependent(mf_table VARCHAR(100))
  RETURNS VOID
  LANGUAGE 'plpgsql'
AS
$$
DECLARE 
    --mf_table VARCHAR(100) = 'condition_test';
    id_array VARCHAR[] = (SELECT ARRAY_AGG(id) FROM mimic_fhir.patient);
BEGIN    
    EXECUTE FORMAT('DROP TABLE IF EXISTS mimic_fhir.%s;', mf_table);
    EXECUTE FORMAT('CREATE TABLE mimic_fhir.%s(
                        id uuid
                        , patient_id uuid
                        , fhir jsonb NOT NULL
                        , PRIMARY KEY(id, patient_id)
                    ) PARTITION BY LIST(patient_id);', mf_table);
    EXECUTE FORMAT('SELECT fhir_etl.fn_partition_builder(''%s'');', mf_table);
    
END;
$$;