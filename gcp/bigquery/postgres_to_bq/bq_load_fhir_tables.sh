declare -a FhirTables=("patient" "condition" "condition_ed" "encounter" "encounter_ed" "encounter_icu"
                       "location" "medication" "medication_administration" "medication_administration_icu"
                       "medication_dispense" "medication_dispense_ed" "medication_mix" "medication_request"
                       "medication_statement_ed" "observation_chartevents" "observation_datetimeevents"
                       "observation_ed" "observation_labevents" "observation_micro_org" "observation_micro_susc"
                       "observation_micro_test" "observation_outputevents" "observation_vital_signs" 
                       "procedure" "procedure_ed" "procedure_ed" "procedure_icu" "specimen" "specimen_lab")


for table in ${FhirTables[@]}; do
    echo Loading $table table
    bq load --source_format=CSV mimic_fhir.$table $GS_CSV_PATH/$table.csv
done
