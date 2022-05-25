#!/bin/bash

# Sort the ndjson files to make them deterministic exports
fhir_profiles=$1
output_path=$2

for profile in $fhir_profiles; do
    echo $profile
    infile="${output_path}/${profile}.ndjson"
    outfile="${output_path}/sorted/${profile}.ndjson"
    cat $infile | jq -s -c 'sort_by(.id)[]' > $outfile
done
