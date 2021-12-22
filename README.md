# mimic-fhir
A version of MIMIC-IV in FHIR. The scripts in the repository will generate the MIMIC-IV FHIR tables in PostgreSQL. Before getting started make sure you have MIMIC-IV loaded into your local Postgres or follow this [MIMIC-IV guide](https://github.com/MIT-LCP/mimic-code/tree/main/mimic-iv/buildmimic/postgres) to set it up.

## Quickstart
1. Clone the repository locally:
```sh
git clone https://github.com/kind-lab/mimic-fhir.git
```
2. Generate the FHIR tables by running [create_fhir_tables.sql](https://github.com/kind-lab/mimic-fhir/blob/mimic-iv-on-fhir/sql/create_fhir_tables.sql) 
```sh
psql -f create_fhir_tables.sql
```
3. Output FHIR json files by running [create_fhir_jsons.sql](https://github.com/kind-lab/mimic-fhir/blob/mimic-iv-on-fhir/sql/create_fhir_jsons.sql)
```sh
psql -f create_fhir_jsons.sql
```
  - May need to update the `outputdir` in create_fhir_jsons.sql on your local machine



## Useful wiki links
- The [FHIR Conversion Asusmptions](https://github.com/kind-lab/mimic-fhir/wiki/FHIR-Conversion-Assumptions) section covers assumptions made during the MIMIC to FHIR process.
- The [HAPI FHIR Server Validation](https://github.com/kind-lab/mimic-fhir/wiki/HAPI-FHIR-Server-Validation) section walks through validating the MIMIC resources against various implementation guides using HAPI FHIR.
