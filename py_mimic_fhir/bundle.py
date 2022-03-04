# FHIR bundle class with options to add entries and send requests to the server
# Created a Bundle class since fhir.resources did not allow construction of the entry
# and request in a pythonic way (there was validation built in that needed both set at once)
import logging
import requests
import json


class Bundle():
    def __init__(self):
        self.resourceType = 'Bundle'
        self.type = 'transaction'
        self.entry = []
        self.response = ''

    def add_entry(self, resources):
        for resource in resources:
            new_request = {}
            new_request['method'] = 'PUT'
            new_request['url'] = resource['resourceType'] + '/' + resource['id']

            new_entry = {}
            new_entry['fullUrl'] = resource['id']
            new_entry['request'] = new_request

            new_entry['resource'] = resource

            self.entry.append(new_entry)

    def json(self):
        return self.__dict__

    def request(self, fhir_server):
        resp = requests.post(
            fhir_server,
            json=self.json(),
            headers={"Content-Type": "application/fhir+json"}
        )
        output = json.loads(resp.text)
        if output['resourceType'] == 'OperationOutcome':
            logging.error(output)
        self.response = output