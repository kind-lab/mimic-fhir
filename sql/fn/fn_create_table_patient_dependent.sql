CREATE OR REPLACE FUNCTION fhir_etl.fn_create_table_patient_dependent(mf_table VARCHAR(100))
  RETURNS VOID
  LANGUAGE 'plpgsql'
AS
$$
BEGIN    
    EXECUTE FORMAT('DROP TABLE IF EXISTS mimic_fhir.%s;', mf_table);
    EXECUTE FORMAT('CREATE TABLE mimic_fhir.%s(
                        id uuid PRIMARY KEY
                        , patient_id uuid NOT NULL
                        , fhir jsonb NOT NULL
                    );', mf_table);   
    EXECUTE FORMAT('CREATE INDEX idx_%s_patient_id ON mimic_fhir.%s (patient_id);', mf_table, mf_table);
END;
$$;
