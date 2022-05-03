#!/usr/bin/env python
import pika
import threading
import sys


class ReceiverExportThread(threading.Thread):
    def __init__(self, queue_name='export_queue'):
        super(ReceiverExportThread, self).__init__()
        self._is_interrupted = False
        self.queue_name = queue_name
        self.connection = pika.BlockingConnection(
            pika.ConnectionParameters(host='localhost')
        )
        self.channel = self.connection.channel()

    def stop(self):
        self._is_interrupted = True

    def receive(self):
        connection = pika.BlockingConnection(
            pika.ConnectionParameters(host='localhost')
        )
        channel = self.connection.channel()
        channel.queue_declare(queue=self.queue_name, durable=True)
        print('ready to receive')
        for message in channel.consume(self.queue_name, inactivity_timeout=1):
            if self._is_interrupted:
                break
            if not all(message):
                print(message)
                break
                continue
            method, properties, body = message
            self.callback(method, properties, body)

    def callback(self, method, properties, body):
        print(f' [x] Received {body.decode()}')
        print(' [x] Done')
        ch.basic_ack(delivery_tag=method.delivery_tag)
