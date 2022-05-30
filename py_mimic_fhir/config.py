class MimicArgs():
    def __init__(self, fhir_server, err_path):
        self.fhir_server = fhir_server
        self.err_path = err_path


class ResultList():
    def __init__(self):
        self.rlist = []

    def update(self, val):
        self.rlist.append(val)

    def get(self):
        return self.rlist
