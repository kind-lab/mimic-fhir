import pytest
import json
from py_mimic_fhir.queue.receiver_export import ReceiverExportThread
from py_mimic_fhir.queue.sender_export import SenderExport


def test_export_send_and_receive():
    resource = 'Patient'
    profile_url = 'http://fhir.mimic.mit.edu/StructureDefinition/mimic-patient'
    fhir_server = 'http://localhost:8080/fhir/'
    message_dict = {}
    message_dict['resource'] = resource
    message_dict['profile_url'] = profile_url
    message_dict['fhir_server'] = fhir_server

    message = json.dumps(message_dict)

    sender = SenderExport()
    receiver = ReceiverExportThread()
    receiver.start()

    sender.send('hello')
    receiver.receive()

    receiver.stop()
    receiver.join()
    sender.close()

    assert False  #to see output
