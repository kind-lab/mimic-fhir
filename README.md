# mimic-fhir

This repository provides code for converting the [MIMIC-IV](https://physionet.org/content/mimiciv/2.2/) and [MIMIC-IV-ED](https://physionet.org/content/mimic-iv-ed/2.2/) databases into [FHIR](https://www.hl7.org/fhir/).

Code in this repository is organized as follows:


* [sql/](/sql/) contains SQL scripts for creating the FHIR tables in PostgreSQL and mapping data from MIMIC-IV/MIMIC-IV-ED
* [py_mimic_fhir/](/py_mimic_fhir/) contains a Python package for importing, validating and exporting FHIR resources from a HAPI FHIR server
* [mimic-profiles/](/mimic-profiles/) (submodule) contains the FHIR profiles and terminology for MIMIC-IV/MIMIC-IV-ED
* [hapi-fhir-jpaserver-starter/](/hapi-fhir-jpaserver-starter/) (submodule) contains a fork of the HAPI FHIR JPA Server Starter project with some modifications to support the MIMIC-IV/MIMIC-IV-ED profiles and terminology
* [mimic-code/](/mimic-code/) (submodule) contains the MIMIC-IV build scripts for building the MIMIC-IV/MIMIC-IV-ED databases in PostgreSQL
* [fhir-packages](/fhir-packages/) contains the FHIR packages for the MIMIC-IV/MIMIC-IV-ED profiles and terminology (currently an empty folder)

- A version of MIMIC-IV-on-FHIR ([original repo here](https://github.com/kind-lab/mimic-fhir)). The scripts and packages in the repository will generate the MIMIC-IV FHIR tables in PostgreSQL, validate in HAPI fhir, and export to ndjson.
- Also know that there are specific instructions for MIMIC-IV and MIMIC-IV-ED to be loaded into your local Postgres. The specific instructions are at [MIMIC-IV guide](https://github.com/MIT-LCP/mimic-code/tree/main/mimic-iv/buildmimic/postgres) and [MIMIC-IV-ED guide](https://github.com/MIT-LCP/mimic-code/tree/main/mimic-iv-ed/buildmimic/postgres). You can follow those instructions, but I've included it all here, but I want to ensure I give credit where it is due. (Note: When following other instructions please use the same db name across both guides ie. `mimiciv`)

## Accessing the data

This repository is provided for those who wish to explore the build process and regenerate the data in FHIR themselves.
For those who are simply interested in the data, there are two PhysioNet projects where the data has already been published:

* [MIMIC-IV FHIR Demo](https://physionet.org/content/mimic-iv-fhir-demo) - A demo project with 100 patients. Openly available.
* [MIMIC-IV FHIR](https://physionet.org/content/mimic-iv-fhir) - The full MIMIC-IV dataset. Requires a credentialed PhysioNet account.

## Building MIMIC-IV on FHIR

Briefly, the steps to convert MIMIC-IV/MIMIC-IV-ED to FHIR are as follows:

1. Clone this repository and its submodules
2. Install PostgreSQL and create a database
3. Download the MIMIC-IV/MIMIC-IV-ED data and load it into PostgreSQL
4. Generate the FHIR tables by running [create_fhir_tables.sql](/sql/create_fhir_tables.sql)

### Detailed instructions (Ubuntu)

#### Install packages

First install git, wget, and postgresql

```sh
# update
sudo apt update
sudo apt install git wget postgresql postgresql-contrib
```

Clone the repository and its submodules.

```sh
# use recurse submodules to also clone the mimic-code/mimic-profiles repo
git clone --recurse-submodules https://github.com/fhir-fli/mimic-fhir.git
```

#### Create a postgres user

Configure a user for the database.
For convenient access, you should pick a username which is identical to your operating system username, that way
you won't have to specify the username when connecting to the database, and authentication is simplified.

```sh
#get into postgres
sudo -i -u postgres
```

```sh 
postgres@desktop:~$ psql
```

```sh
# For this, the user needs to be the same as the username you are using on the current computer you're using
# replace '${PASSWORD}' with your actual password, but leave the single quotes around it
postgres=# CREATE USER grey CREATEDB password '${PASSWORD}';

postgres=# exit
```

```sh
postgres@desktop:~$ exit
```

#### Download the data and structure it in Postgresql

- Note in the below, ```<USERNAME>``` is your physionet username
- It is around ~6 GB of data and so the download can take some time, 30-40 minutes is not unusual
- If that doesn't work, go to the bottom of these websites, and you can copy the commands
  - [mimiciv](https://physionet.org/content/mimiciv/2.2/)
  - [mimic-iv-ed](https://physionet.org/content/mimic-iv-ed/2.2/)

The following commands should be run in the mimic-fhir directory.

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
psql -d mimiciv -f mimic-code/mimic-iv/buildmimic/postgres/create.sql

# take note of the mimiciv version you're on and change the directory accordingly, this one takes a while
psql -d mimiciv -v ON_ERROR_STOP=1 -v mimic_data_dir=mimiciv/2.2 -f mimic-code/mimic-iv/buildmimic/postgres/load_gz.sql

# The first time you do this, the scripts delete ("drop" in sql parlance) things before you create them to remove old versions.
# This produces many warnings, you can safely ignore them.
psql -d mimiciv -v ON_ERROR_STOP=1 -v mimic_data_dir=mimiciv/2.2 -f mimic-code/mimic-iv/buildmimic/postgres/constraint.sql
psql -d mimiciv -v ON_ERROR_STOP=1 -v mimic_data_dir=mimiciv/2.2 -f mimic-code/mimic-iv/buildmimic/postgres/index.sql

# We're basically just going to repeat with the mimic ED data
psql -d mimiciv -f mimic-code/mimic-iv-ed/buildmimic/postgres/create.sql
psql -d mimiciv -v ON_ERROR_STOP=1 -v mimic_data_dir=mimicived/2.2/ed -f mimic-code/mimic-iv-ed/buildmimic/postgres/load_gz.sql
psql -d mimiciv -v ON_ERROR_STOP=1 -v mimic_data_dir=mimicived/2.2/ed -f mimic-code/mimic-iv-ed/buildmimic/postgres/constraint.sql
psql -d mimiciv -v ON_ERROR_STOP=1 -v mimic_data_dir=mimicived/2.2/ed -f mimic-code/mimic-iv-ed/buildmimic/postgres/index.sql

# validate that the setup is correct
psql -d mimiciv -f mimic-code/mimic-iv-ed/buildmimic/postgres/validate.sql
psql -d mimiciv -f mimic-code/mimic-iv/buildmimic/postgres/validate.sql
```

#### Conversion

- Generate the FHIR tables by running [create_fhir_tables.sql](https://github.com/kind-lab/mimic-fhir/blob/main/sql/create_fhir_tables.sql) found in the folder `mimic-fhir/sql`
- IMPORTANT: 
  - Realistically, you probably need 2TB of FREE space on the device you're using
  - This is a lengthy process. Just so you can know what you should expect, I ran this on a machine with:
    - AMD® Ryzen 9 3900xt 12-core processor × 24 
    - 64 GB RAM
  - It took ~12 hours

```sh
cd sql
psql -d mimiciv -f create_fhir_tables.sql
```

- In order to confirm the tables were generated correctly, it is recommended to run the [validate_fhir_tables.sql](https://github.com/kind-lab/mimic-fhir/blob/main/sql/validate_fhir_tables.sql).

```sh
psql -d mimiciv -f validate_fhir_tables.sql
```


#### Export to ndjson files

- Export the FHIR resources to ndjson files in `<output-dir>` by running [create_fhir_jsons.sql](...)  found in the folder `mimic-fhir/sql`
(replace `<output-dir>` with the desired existing and empty output directory).

```sh
psql -d mimiciv -v "outputdir=<output-dir>" -f sql/create_fhir_jsons.sql
````

## HAPI FHIR for use in validation/export

- The first step in validation/export is getting the fhir server running. In our case we will use HAPI FHIR.
- There is a fork of the HAPI FHIR server with a few modifications to enable use with the FHIR data

```sh
# leave the mimic-fhir/sql directory and clone the hapi-fhir repo
cd ../.. && git clone https://github.com/kind-lab/hapi-fhir-jpaserver-starter.git

createdb hapi_r4
```

- They created a \*.env\* file already in the mimic-fhir directory. 
- Change the SQLUSER and SQLPASS. Those should be the same as you set them at the beginning of this process.
- Choose the paths you're going to use for the MIMIC_JSON_PATH, FHIR_BUNDLE_ERROR_PATH, MIMIC_FHIR_LOG_PATH
- You'll need to make sure java and maven are installed for this next section
- The *application.yaml* file in the hapi-fhir-jpaserver-starter project also needs the username and password changed at the beginning to the same ones you have been using
- then run: 

```sh
cd hapi-fhir-jpaserver-starter
mvn jetty:run
```

- The initial loading of hapi fhir will be around 10-15 minutes, subsequent loads will be faster

## PY_MIMIC_FHIR

- Configure py_mimic_fhir package for use
- Post terminology to HAPI-FHIR using py_mimic_fhir
- Ensure the environment variable `MIMIC_TERMINOLOGY_PATH` is set and pointing to the latest terminology files `mimic-profiles/input/resources`

```sh
cd ../mimic-fhir
export $(grep -v '^#' .env | xargs)
pip install -e .
```

- there are some packages that seem to be required before you can run the terminology post command

```sh
pip install google-cloud
pip install google-cloud-pubsub
pip install google-api-python-client
pip install psycopg2-binary
pip install pandas-gbq
pip install fhir
pip install fhir-resources
```

- Run the terminology post command in py_mimic_fhir: 

```sh
python py_mimic_fhir terminology --post
```

- Load reference data bundles into HAPI-FHIR using py_mimic_fhir
- Initialize data on the HAPI-FHIR server, so patient bundles can reference the data resources
- The data tables for medication and organization only need to be loaded in once to your HAPI-FHIR server. To ensure these resources are loaded in, the first time you run mimic-fhir you must run

```sh
python3 py_mimic_fhir validate --init
```

- Validate mimic-fhir against mimic-profiles IG  
- After step 6 has been run once, you can proceeded to this step to validate some resources! In your terminal (with all the env variables) run: 

```sh
python3 py_mimic_fhir validate --num_patients 5
```

- Any failed bundles will be written to your log folder specified in *.env*

- Export mimic-fhir to ndjson
  - Using the py_mimic_fhir package you can export all the resources on the server to ndjson

```sh
python3 py_mimic_fhir export --export_limit 100
```

- `export_limit` will reduce how much is written out to file. It limits how many binaries are written out. Each binary ~1000 resources. So in this case the limit of 1 will output 1000 resources into ndjsons 
- The outputted ndjson will be written to the MIMIC_JSON_PATH folder specified inthe *.env*


## Generating terminology resources

The `bin/psql-export-trm.py` script can be used to generate terminology resources such as code systems and value sets
from the `fhir_trm` schema of mimic database. These resources can be used to update the MIMIC code systems and value sets defintions in MIMIC-IV IG 
(`mimic-profile/input/resources`).

To update the resource generate the terminology tables in postgresql SQL first with `sql/create_fhir_terminology.sql`
(or `sql/create_fhir_terminology.sql) and then run the script with the following command (replace the placeholders with the actual values):

```sh
python bin/psql-export-trm.py \  
  --db-name "${DATABASE}" \
  --db-user "${USER}" \
  --db-pass "${PGPASSWORD}" \
  --date "2022-09-21T13:59:43-04:00" \
  mimic-profiles/input/resources 
```

The script requires `click` python package (in addition to the packages listed in the section above).

## Useful wiki links
- The [FHIR Conversion Asusmptions](https://github.com/kind-lab/mimic-fhir/wiki/FHIR-Conversion-Assumptions) section covers assumptions made during the MIMIC to FHIR process.
- The [HAPI FHIR Server Validation](https://github.com/kind-lab/mimic-fhir/wiki/HAPI-FHIR-Server-Validation) section walks through validating the MIMIC resources against various implementation guides using HAPI FHIR.
- The [py_mimic_fhir CLI](https://github.com/kind-lab/mimic-fhir/wiki/py_mimic_fhir-CLI) section details the arguments that can be used in the CLI
- The [Bundle and Export](https://github.com/kind-lab/mimic-fhir/wiki/HAPI-Bundles-and-Export) section goes over the bundling process and export execution.
