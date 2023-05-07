# mimic-fhir

- A version of MIMIC-IV-on-FHIR ([original repo here](https://github.com/kind-lab/mimic-fhir)). The scripts and packages in the repository will generate the MIMIC-IV FHIR tables in PostgreSQL, validate in HAPI fhir, and export to ndjson.
- Also know that there are specific instructions for MIMIC-IV and MIMIC-IV-ED to be loaded into your local Postgres. The specific instructions are at [MIMIC-IV guide](https://github.com/MIT-LCP/mimic-code/tree/main/mimic-iv/buildmimic/postgres) and [MIMIC-IV-ED guide](https://github.com/MIT-LCP/mimic-code/tree/main/mimic-iv-ed/buildmimic/postgres). You can follow those instructions, but I've included it all here, but I want to ensure I give credit where it is due. (Note: When following other instructions please use the same db name across both guides ie. `mimiciv`)

## Prerequisites

```sh
# update
sudo apt update

# install git and wget
sudo apt install git wget

# clone repo
git clone https://github.com/kind-lab/mimic-fhir.git && cd mimic-fhir/mimic-code
```

## Postgresql
```sh
# install
sudo apt install postgresql postgresql-contrib

#get into postgres
sudo -i -u postgres
```

```sh 
postgres@desktop:~$ psql
```


```sh
# For this, the user needs to be the same as the username you are using on the current computer you're using
postgres=# CREATE USER grey CREATEDB password <PASSWORD>;

postgres=# exit
```

```sh
postgres@desktop:~$ exit
```

## Download the data and structure it in Postgresql

- Note in the below, "<USERNAME>" is your physionet username
- It's a fair amount of data, but it can take some time, 30-40 minutes is not unusual
- If that doesn't work, go to the bottom of these websites, and you can copy the commands
- [mimiciv](https://physionet.org/content/mimiciv/2.2/)
- [mimic-iv-ed](https://physionet.org/content/mimic-iv-ed/2.2/)

```sh
wget -r -N -c -np --user <USERNAME> --ask-password https://physionet.org/files/mimiciv/2.2/
wget -r -N -c -np --user <USERNAME> --ask-password https://physionet.org/files/mimic-iv-ed/2.2/

# move the actual data files
mv physionet.org/files/mimiciv mimiciv 
mv physionet.org/files/mimic-iv-ed mimicived

# delete the rest
rm -r physionet.org/

# creates the database itself
createdb mimiciv
psql -d mimiciv -f mimic-iv/buildmimic/postgres/create.sql

# take note of the mimiciv version you're on and change the directory accordingly, this one takes a while
psql -d mimiciv -v ON_ERROR_STOP=1 -v mimic_data_dir=mimiciv/2.2 -f mimic-iv/buildmimic/postgres/load_gz.sql

# The first time you do this, the scripts delete ("drop" in sql parlance) things before you create them to remove old versions. This produces a warning, you can safely ignore it

# I get a number of Notices about constraints not existing for this one
psql -d mimiciv -v ON_ERROR_STOP=1 -v mimic_data_dir=mimiciv/2.2 -f mimic-iv/buildmimic/postgres/constraint.sql

# Also notices about indexes not existing
psql -d mimiciv -v ON_ERROR_STOP=1 -v mimic_data_dir=mimiciv/2.2 -f mimic-iv/buildmimic/postgres/index.sql

# We're basically just going to repeat with the mimic ED data
psql -d mimiciv -f mimic-iv-ed/buildmimic/postgres/create.sql
psql -d mimiciv -v ON_ERROR_STOP=1 -v mimic_data_dir=mimicived/2.2/ed -f mimic-iv-ed/buildmimic/postgres/load_gz.sql

# In the mimic-iv-ed directory, the constraints.sql has the schema listed as mimic_ed, instead of mimiciv_ed, which is the schema in the other files. In this repo I've changed, but if you go with the original repo, you'll probably have to change it
psql -d mimiciv -v ON_ERROR_STOP=1 -v mimic_data_dir=mimicived/2.2/ed -f mimic-iv-ed/buildmimic/postgres/constraint.sql

# Same notices about indexes not existing
psql -d mimiciv -v ON_ERROR_STOP=1 -v mimic_data_dir=mimicived/2.2/ed -f mimic-iv-ed/buildmimic/postgres/index.sql

# validate that the setup is correct
psql -U postgres -d mimiciv -f mimic-iv-ed/buildmimic/postgres/validate.sql
psql -U postgres -d mimiciv -f mimic-iv/buildmimic/postgres/validate.sql
```

## Conversion

- Generate the FHIR tables by running [create_fhir_tables.sql](https://github.com/kind-lab/mimic-fhir/blob/main/sql/create_fhir_tables.sql) found in the folder `mimic-fhir/sql`
- IMPORTANT: 
  - this takes a long time and requires a lot of space. I kept running out of space when I tried to do it at first.
  - I recommend having 800GB, at probably 1TB of space free on the device you're using
  - This is a lengthy process. Just so you can know what you should expect, I ran this on a machine with:
    - Intel(R) Core(TM) i7-6500U CPU @ 2.50GHz
    - 16 GB RAM
  - It took over 12 hours

```sh
cd ../sql
psql -U postgres -d mimiciv -f create_fhir_tables.sql
```

- In order to confirm the tables were generated correctly, it is recommended to run the [validate_fhir_tables.sql](https://github.com/kind-lab/mimic-fhir/blob/main/sql/validate_fhir_tables.sql).

```sh
psql -d mimiciv -f validate_fhir_tables.sql
```

## HAPI FHIR for use in validation/export

- The first step in validation/export is getting the fhir server running. In our case we will use HAPI FHIR.
- The nice folks at kind-lab made a fork of the pa starter server

```sh
git clone https://github.com/kind-lab/hapi-fhir-jpaserver-starter.git
```

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