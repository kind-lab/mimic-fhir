import time


class MimicArgs():
    def __init__(self, fhir_server, err_path, validator):
        self.fhir_server = fhir_server
        self.err_path = err_path
        self.validator = validator


class GoogleArgs():
    def __init__(
        self, project, topic, location, bucket, dataset, fhirstore,
        export_folder
    ):
        self.project = project
        self.topic = topic
        self.location = location
        self.bucket = bucket
        self.dataset = dataset
        self.fhirstore = fhirstore
        self.export_folder = export_folder
        self.blob_dir = f'bundle-loading/bundles-{time.strftime("%Y%m%d-%H%M%S")}'


class ResultList():
    def __init__(self):
        self.rlist = []

    def update(self, val):
        self.rlist.append(val)

    def get(self):
        return self.rlist
