# mimic-fhir
A version of MIMIC-IV-on-FHIR. The scripts and packages in the repository will generate the MIMIC-IV FHIR tables in PostgreSQL, validate in HAPI fhir, and export to ndjson. Before getting started make sure you have MIMIC-IV loaded into your local Postgres or follow this [MIMIC-IV guide](https://github.com/MIT-LCP/mimic-code/tree/main/mimic-iv/buildmimic/postgres) to set it up.

## Quickstart
1. Clone the repository locally:
```sh
git clone https://github.com/kind-lab/mimic-fhir.git
```
2. Generate the FHIR tables by running [create_fhir_tables.sql](https://github.com/kind-lab/mimic-fhir/blob/main/sql/create_fhir_tables.sql) found in the folder `mimic-fhir/sql`
```sh
psql -f create_fhir_tables.sql
```
3. Set up HAPI FHIR for use in validation/export
    - The first step in validation/export is getting the fhir server running. In our case we will use HAPI FHIR.
    - We made a fork of the jpa starter server: `git clone https://github.com/kind-lab/hapi-fhir-jpaserver-starter.git`
    - Create the postgres database hapi_r4 that will be used in HAPI: 
      - From the terminal enter psql: `psql`
      - Create hapi database in sql: `CREATE DATABASE hapi_r4;`
      - Exit psql: `\q` 
    - The *application.yaml* file in the hapi-fhir-jpaserver-starter project was modified to point to the mimic implementation guide
      - The mimic implementation guide is stored in the [kindlab fhir-packages](https://github.com/kind-lab/fhir-packages) repo.
    - Start the HAPI FHIR server by going to the *hapi-fhir-jpaserver-starter* folder and running: `mvn jetty:run`
      - The initial loading of hapi fhir will be around 10-15 minutes, subsequent loads will be faster
4. Validate mimic-fhir against mimic-profiles IG  
    - Before starting the py_mimic_fhir package you need to add a *.env* file in mimic-fhir to match your local settings. An example *.env.example* file is available in the folder as reference. These environment variables will be used in the next step.
      - Export these environment variables to your terminal for ease of use. Run `export $(grep -v '^#' .env | xargs)`
    - Next get the py_mimic_fhir package setup and ready to validate
      - Move into the *mimic-fhir* folder on your local machine
      - Install the package using `pip install -e .`
      - Validate some resources! In your terminal (with all the env variables) run: `python py_mimic_fhir validate --num_patients 5`
        - Any failed bundles will be written to your log folder specified in *.env*

5. Export mimic-fhir to ndjson
    - Using the py_mimic_fhir package you can export all the resources on the server to ndjson
    - Run `python py_mimic_fhir export --export_limit 1`
      - `export_limit` will reduce how much is written out to file. It limits how many binaries are written out. Each binary ~1000 resources. So in this case the limit of 1 will output 1000 resources into ndjsons 
      - The outputted ndjson will be written to the MIMIC_JSON_PATH folder specified inthe *.env*


## Useful wiki links
- The [FHIR Conversion Asusmptions](https://github.com/kind-lab/mimic-fhir/wiki/FHIR-Conversion-Assumptions) section covers assumptions made during the MIMIC to FHIR process.
- The [HAPI FHIR Server Validation](https://github.com/kind-lab/mimic-fhir/wiki/HAPI-FHIR-Server-Validation) section walks through validating the MIMIC resources against various implementation guides using HAPI FHIR.
- The [py_mimic_fhir CLI](https://github.com/kind-lab/mimic-fhir/wiki/py_mimic_fhir-CLI) section details the arguments that can be used in the CLI
- The [Bundle and Export](https://github.com/kind-lab/mimic-fhir/wiki/HAPI-Bundles-and-Export) section goes over the bundling process and export execution.