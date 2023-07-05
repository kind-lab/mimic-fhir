# mimic-fhir
A version of MIMIC-IV-on-FHIR. The scripts and packages in the repository will generate the MIMIC-IV FHIR tables in PostgreSQL, validate in HAPI fhir, and export to ndjson. Before getting started make sure you have MIMIC-IV and MIMIC-IV-ED loaded into your local Postgres or follow [MIMIC-IV guide](https://github.com/MIT-LCP/mimic-code/tree/main/mimic-iv/buildmimic/postgres) and [MIMIC-IV-ED guide](https://github.com/MIT-LCP/mimic-code/tree/main/mimic-iv-ed/buildmimic/postgres) respectively to set it up. (Note: When following instructions please use the same db name across both guides ie. `mimiciv`) To confirm the database is setup, do the following steps:
  - Upon loading both the MIMIC-IV and MIMIC-IV-ED data, validate that the data was loaded into postgres by running the following command: `psql -U postgres -d <name of db> -f validate_demo.sql` within their respective projects(`mimic-code/mimic-iv-ed/buildmimic/postgres/` & `mimic-code/mimic-iv/buildmimic/postgres/`)
  - When all test cases pass you may proceed to creating the fhir tables in Quickstart.

  Note: It is recommended for users to install [miniforge](https://github.com/conda-forge/miniforge) for easy setup. Once installed, make sure to connect to the environment with the following commend `conda activate <environmentName>`. To exit the environment do `conda deactivate `.
`

## Prerequisite

Have postgresql

```
sudo apt-get install postgres
```

This takes a lot of data, you may need to use a different tablespace

```

```

Clone the repo

```
git clone git@github.com:kind-lab/mimic-fhir.git
```

Have MIMIC-IV and MIMIC-IV-ED built on a local postgres database.

```sh
USERNAME=alistairewj
wget -rNcnp --user $USERNAME --ask-password --cut-dirs=2 https://physionet.org/files/mimiciv/2.2/
wget -rNcnp --user $USERNAME --ask-password --cut-dirs=2 https://physionet.org/files/mimic-iv-ed/2.2/
mkdir -p mimic-iv
mv physionet.org/2.2 mimic-iv/
git clone https://github.com/MIT-LCP/mimic-code.git
# load mimic-iv icu/hosp
cd mimic-code/mimic-iv/buildmimic/postgres
psql -d mimic -f create.sql
psql -d mimic -f load_gz.sql -v mimic_data_dir=../../../../mimic-iv/2.2
# load mimic-iv ed
cd ../../../mimic-iv-ed/buildmimic/postgres
psql -d mimic -f create.sql
psql -d mimic -f load_gz.sql -v mimic_data_dir=../../../../mimic-iv/2.2
```

## Quickstart
1. Clone the repository locally:  
```sh
git clone https://github.com/kind-lab/mimic-fhir.git
```
2. Generate the FHIR tables by running [create_fhir_tables.sql](https://github.com/kind-lab/mimic-fhir/blob/main/sql/create_fhir_tables.sql) found in the folder `mimic-fhir/sql`
```sh
psql -f create_fhir_tables.sql
```
  - In order to confirm the tables were generated correctly, it is recommended to run the [validate_fhir_tables.sql](https://github.com/kind-lab/mimic-fhir/blob/main/sql/validate_fhir_tables.sql) file with the following command:
    - `psql -d <name of db> -f validate_fhir_tables.sql`
  - If all the test cases pass, proceed to step 3.

3. Set up HAPI FHIR for use in validation/export
    - The first step in validation/export is getting the fhir server running. In our case we will use HAPI FHIR.
    - We made a fork of the jpa starter server: `git clone https://github.com/kind-lab/hapi-fhir-jpaserver-starter.git`
    - Create the postgres database hapi_r4 that will be used in HAPI: 
      - From the terminal enter psql: `psql`
      - Create hapi database in sql: `CREATE DATABASE hapi_r4;`
      - Exit psql: `\q`
  

    3.1. Setting up the .env file
      - Before starting the py_mimic_fhir package you need to add a *.env* file in mimic-fhir to match your local settings. An example *.env.example* file is available in the folder as reference. 


    3.2. Starting the FHIR Server
      - The *application.yaml* file in the hapi-fhir-jpaserver-starter project was modified to point to the mimic implementation guide
        - The mimic implementation guide is stored in the [kindlab fhir-packages](https://github.com/kind-lab/fhir-packages) repo.
      - Start the HAPI FHIR server by going to the *hapi-fhir-jpaserver-starter* folder and running: `mvn jetty:run`
        - The initial loading of hapi fhir will be around 10-15 minutes, subsequent loads will be faster

4. Configure py_mimic_fhir package for use
    - Export these environment variables to your terminal for ease of use. Run `export $(grep -v '^#' .env | xargs)`
    - Next get the py_mimic_fhir package setup and ready to validate
      - Move into the *mimic-fhir* folder on your local machine
      - Install the package using `pip install -e .`


5.  Post terminology to HAPI-FHIR using py_mimic_fhir

    - The default load of HAPI-FHIR with the mimic implementation guide does not fully expand all terminology. To ensure full expansion, we need to post the terminology directly. To do this
        - Pull from the [mimic-profiles](https://github.com/kind-lab/mimic-profiles)`
        - Ensure the environment variable `MIMIC_TERMINOLOGY_PATH` is set and pointing to the latest terminology files from [mimic-profiles](https://github.com/kind-lab/mimic-profiles/tree/main/input/resources)
        - Run the terminology post command in py_mimic_fhir: `python py_mimic_fhir terminology --post`

6.  Load reference data bundles into HAPI-FHIR using py_mimic_fhir

    - Initialize data on the HAPI-FHIR server, so patient bundles can reference the data resources
    - The data tables for medication and organization only need to be loaded in once to your HAPI-FHIR server. To ensure these resources are loaded in, the first time you run mimic-fhir you must run:
        - `python py_mimic_fhir validate --init`


7. Validate mimic-fhir against mimic-profiles IG  
      - After step 6 has been run once, you can proceeded to this step to validate some resources! In your terminal (with all the env variables) run: `python py_mimic_fhir validate --num_patients 5`
        - Any failed bundles will be written to your log folder specified in *.env*



8. Export mimic-fhir to ndjson
    - Using the py_mimic_fhir package you can export all the resources on the server to ndjson
    - Run `python py_mimic_fhir export --export_limit 1`
      - `export_limit` will reduce how much is written out to file. It limits how many binaries are written out. Each binary ~1000 resources. So in this case the limit of 1 will output 1000 resources into ndjsons 
      - The outputted ndjson will be written to the MIMIC_JSON_PATH folder specified inthe *.env*


## Useful wiki links
- The [FHIR Conversion Asusmptions](https://github.com/kind-lab/mimic-fhir/wiki/FHIR-Conversion-Assumptions) section covers assumptions made during the MIMIC to FHIR process.
- The [HAPI FHIR Server Validation](https://github.com/kind-lab/mimic-fhir/wiki/HAPI-FHIR-Server-Validation) section walks through validating the MIMIC resources against various implementation guides using HAPI FHIR.
- The [py_mimic_fhir CLI](https://github.com/kind-lab/mimic-fhir/wiki/py_mimic_fhir-CLI) section details the arguments that can be used in the CLI
- The [Bundle and Export](https://github.com/kind-lab/mimic-fhir/wiki/HAPI-Bundles-and-Export) section goes over the bundling process and export execution.