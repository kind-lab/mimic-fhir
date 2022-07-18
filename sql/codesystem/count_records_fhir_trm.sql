WITH tbl AS (
    SELECT 
        table_schema
        , TABLE_NAME
    FROM information_schema.tables
    WHERE table_schema = 'fhir_trm'
)
SELECT 
    table_schema
    , TABLE_NAME
    , (xpath('/row/c/text()', query_to_xml(format('select count(*) as c from %I.%I', table_schema, TABLE_NAME), FALSE, TRUE, '')))[1]::text::int AS rows_n
FROM tbl
ORDER BY table_name ASC;
