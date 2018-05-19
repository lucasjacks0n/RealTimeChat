# messaging/consumers.py
 
from asgiref.sync import async_to_sync
from channels.generic.websocket import JsonWebsocketConsumer
from channels.db import database_sync_to_async
from channels.layers import get_channel_layer
                     
from userauth import models as user_models
from messaging import models as messaging_models
from . import serializers
                     
                     
class ChatConsumer(JsonWebsocketConsumer):
                         
    def connect(self):
        """User connects to socket
                     
         - channel is added to each thread group they are included in. 
         - channel_name is added to the session so that it can be referenced later in views.py.
        """
        if self.scope["user"].is_authenticated:
            # add connection to existing channel groups
            for thread in messaging_models.MessageThread.objects.filter(clients=self.scope["user"]).values('hash_id'):
                async_to_sync(self.channel_layer.group_add)(thread['hash_id'], self.channel_name)
            # store client channel name in the user session
            self.scope['session']['channel_name'] = self.channel_name
            self.scope['session'].save()
            # accept client connection
            self.accept()


    def disconnect(self, close_code):
        """User is disconnected
                     
         - user will leave all groups and the channel name is removed from the session.
        """
        # remove channel name from session
        if self.scope["user"].is_authenticated:
            if 'channel_name' in self.scope['session']:
                del self.scope['session']['channel_name']
                self.scope['session'].save()
            async_to_sync(self.channel_layer.group_discard)(self.scope["user"].hash_id, self.channel_name)


    def receive_json(self, content):
        """User sends a message
                     
         - read all messages if data is read message
         - send message to thread and group socket if text message
         - Message is sent to the group associated with the message thread
        """
        if 'read' in content:
            # client specifies they have read a message that was sent
            thread = messaging_models.MessageThread.objects.get(hash_id=str(content['read']),clients=self.scope["user"])
            thread.mark_read(self.scope["user"])
        elif 'message' in content:
            message = content['message']
            # extra security is added when we specify clients=p
            thread = messaging_models.MessageThread.objects.get(hash_id=message['id'],clients=self.scope["user"])
            # forward chat message over group channel
            new_message = thread.add_message_text(message['text'],self.scope["user"])
            async_to_sync(self.channel_layer.group_send)(
                thread.hash_id, {
                    "type": "chat.message",
                    "message": serializers.MessageSerializer(new_message).data,
                }
            )


    def chat_message(self, event):
        """chat.message type"""
        message = event['message']
        self.send_json(content=message)
