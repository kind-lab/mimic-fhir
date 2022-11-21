
py-mimic-fhir
==========

The py-mimic-fhir package is used to provide functions to convert MIMIC to FHIR. This package is dependent on:
- [MIMIC-IV](https://physionet.org/content/mimiciv/1.0/) database installed
- MIMIC-FHIR [SQL scripts](https://github.com/kind-lab/mimic-fhir/blob/main/sql/create_fhir_tables.sql) run
- environment variables set with [.env](https://github.com/kind-lab/mimic-fhir/blob/main/.env.example)

## py_mimic_fhir modes
------------------------
There are three modes:
1. `validate` - Allows the user to validate N patients
    - `--num_patients` specifies number of patients to validate.
    - `--export` allows user to export resources after validation completes.
    - `--export_limit` specifies the limit of resources exported. If not specified will export all resources.
    - `--rerun` flag to rerun failed bundles 
    - `--cores` allows the user to specify how many cores to use in parallel processing, default to single core
2. `export` - Allows the user to export resources to file. 
    - `--export_limit` specifies the limit of resources exported. If not specified will export all resources.
    - `--patient_bundle` flag to export patient-everything bundles from GCP
    - `--num_patients` specifies the number of patients to export patient-everything bundles
    - `--count` specifies number of resources allowed per page of patient-everything request
    - `--resource_types` specifies resource types to be included in patient-everything bundles. Comma separated list
    - `--ndjson_by_patient` flag to export NDJSON by patient for Postgres
3. `terminology` - Generate CodeSystems and ValueSets for the latest MIMIC version
    - `--version` specifies the version of the terminology. This should be synced up with the MIMIC-IV version
    - `--status` specifies the status either as draft or complete. Defaults to draft
    - `--post` will post terminology stored in the terminology folder to the specified FHIR server
    - `--generate_and_post` will generate all the terminology and post immediately to the FHIR server

A couple example calls:
- Validation call: `py_mimic_fhir validate --num_patients 5`
- Validation call with export: `py_mimic_fhir validate --num_patients 5 --export`
- Re-validate failed bundles: `py_mimic_fhir validate --rerun`
- Validate in parallel: `py_mimic_fhir validate --num_patients=40 --cores=4`
- Export all: `py_mimic_fhir export`
- Export limited amount: `py_mimic_fhir export --export_limit 1`
- Export patient-everything: `py_mimic_fhir export --patient_bundle --num_patients=100 --resource_types='Patient,Encounter,Condition'`
- Export ndjson by patient: `py_mimic_fhir export --ndjson_by_patient`
- Terminology generation call: `py_mimic_fhir terminology --version 0.4 --status complete`
- Terminology post call: `py_mimic_fhir terminology --post`
- Terminology generate and post call: `py_mimic_fhir terminology --generate_and_post --version 0.4`


## py_mimic_fhir environment variables
Along with the main arguments that the user enters, there are expected environment variables. The user should export all environment variables found in their *.env* to the bash using `source .env`. The variables pulled into py_mimic_fhir are:
| Argument  | Environment variable  |  Notes |
|---|---|---|
| --sqluser | SQLUSER | The SQL database username |
| --sqlpass | SQLPASS | The SQL database password |
| --dbname_mimic | DBNAME_MIMIC | The name of the mimic database locally |
| --host | DBHOST | Where the database is hosted (typically localhost) |
| --port | PGPORT | Which port the database is located on|
| --fhir_server | FHIR_SERVER | The fhir server, in our case HAPI |
| --output_path | MIMIC_JSON_PATH | The output path for exported resources |
| --log_path | MIMIC_FHIR_LOG_PATH | The path to the log files |
| --dbname_hapi | DBNAME_HAPI | The name of the hapi database locally |
| --terminology_path | MIMIC_TERMINOLOGY_PATH | The directory to output terminology to |
| --err_path | MIMIC_FHIR_LOG_PATH | The directory for logs to be stored |
| --gcp_project | GCP_PROJECT | The GCP Project name|
| --gcp_topic | GCP_TOPIC | The GCP topic name to submit bundles to|
| --gcp_location | GCP_LOCATION | The GCP location of services|
| --gcp_bucket | GCP_BUCKET | The Google Cloud Storage bucket where bundle errors can be logged|
| --gcp_dataset | GCP_DATASET | Google Healthcare API dataset|
| --gcp_fhirstore | GCP_FHIRSTORE | Google Healthcare API FHIR store|
| --gcp_export_folder | GCP_EXPORT_FOLDER | Google Cloud Storage folder to export resources to|
| --validator | FHIR_VALIDATOR | FHIR Validator being used. One of HAPI, GCP, or JAVA|
| --db_mode | BD_MODE | Database mode, either Postgres or BigQuery|
