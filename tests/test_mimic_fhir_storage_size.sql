SELECT schema_name, 
    pg_size_pretty(sum(table_size)::bigint) AS pg_schema_size
FROM (
    SELECT 
        pg_catalog.pg_namespace.nspname as schema_name,
        pg_relation_size(pg_catalog.pg_class.oid) as table_size
    FROM   
        pg_catalog.pg_class
        JOIN pg_catalog.pg_namespace ON relnamespace = pg_catalog.pg_namespace.oid
) t
WHERE schema_name = 'mimic_fhir'
GROUP BY schema_name