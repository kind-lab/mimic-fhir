# ----------------- Terminology Validation ---------------------
# Purpose: Test the valuesets and codesystem from the mimic package
# Method:  Ensure that the valuesets have been expanded and that a code can
#          be validated against it using $validate

import json
import requests
import logging


# Generic function to validate codes against ValueSet in HAPI fhir
def vs_validate_code(valueset, code):
    server


# Generic function to validate codes against CodeSystem in HAPI fhir
def cs_validate_code(codesystem, code):
    i = 5
