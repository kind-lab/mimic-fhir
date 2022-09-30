CREATE OR REPLACE FUNCTION fhir_etl.fn_partition_builder(mf_table VARCHAR(100))
  RETURNS VOID
  LANGUAGE 'plpgsql'
AS
$$
DECLARE 
    --mf_table VARCHAR(100) = 'condition_test';
    id_array VARCHAR[] = (SELECT ARRAY_AGG(id) FROM mimic_fhir.patient);
BEGIN
    FOR i IN 1..array_upper(id_array, 1)
    LOOP
        EXECUTE FORMAT('CREATE TABLE %s partition of mimic_fhir.%s for values in (''%s'');', mf_table || i, mf_table, id_array[i]);
    END LOOP;
END;
$$;