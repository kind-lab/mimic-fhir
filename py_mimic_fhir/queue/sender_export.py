import pika


class SenderExport():
    def __init__(self, queue_name='export_queue'):
        self.queue_name = queue_name
        self.connection = pika.BlockingConnection(
            pika.ConnectionParameters(host='localhost')
        )
        self.channel = self.connection.channel()

    def send(self, message):
        self.channel.queue_declare(queue=self.queue_name, durable=True)
        self.channel.basic_publish(
            exchange='',
            routing_key='export_queue',
            body=message.encode('utf-8')
        )

    def close(self):
        self.connection.close()
