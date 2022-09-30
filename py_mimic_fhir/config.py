import time
from google.cloud import pubsub_v1


class MimicArgs():
    def __init__(self, fhir_server, err_path, validator):
        self.fhir_server = fhir_server
        self.err_path = err_path
        self.validator = validator


class PatientEverythingArgs():
    def __init__(
        self, patient_bundle, num_patients, resource_types, topic, count
    ):
        self.patient_bundle = patient_bundle
        self.num_patients = num_patients
        self.resource_types = resource_types
        self.topic = topic
        self.count = str(count)
        self.blob_dir = f'patient-everything/bundles-{time.strftime("%Y%m%d-%H%M%S")}'


class GoogleArgs():
    def __init__(
        self,
        project,
        topic,
        location,
        bucket,
        dataset,
        fhirstore,
        export_folder,
        blob_dir=None
    ):
        self.project = project
        self.topic = topic
        self.location = location
        self.bucket = bucket
        self.dataset = dataset
        self.fhirstore = fhirstore
        self.export_folder = export_folder
        if blob_dir is None:
            self.blob_dir = f'bundle-loading/bundles-{time.strftime("%Y%m%d-%H%M%S")}'
        else:
            self.blob_dir = blob_dir
        self.publisher = pubsub_v1.PublisherClient()
        self.topic_path = self.publisher.topic_path(project, topic)


class ResultList():
    def __init__(self):
        self.rlist = []

    def update(self, val):
        self.rlist.append(val)

    def get(self):
        return self.rlist
