# messaging/serializers.py
 
from rest_framework import serializers
                     
from . import models
                     
                     
class MessageSerializer(serializers.ModelSerializer):
    id = serializers.CharField(source='hash_id', read_only=True)
    sender_id = serializers.CharField(source='sender.hash_id', read_only=True)
    sender_name = serializers.CharField(source='sender.username', read_only=True)
    thread_id = serializers.CharField(source='thread.hash_id', read_only=True)
                     
    class Meta:
        model = models.Message
        fields = ('id','date','text','sender_id','sender_name','thread_id')
                     
                     
class MessageListSerializer(serializers.ListSerializer):
    child = MessageSerializer()
    many = True
    allow_null = True


class MessageThreadSerializer(serializers.ModelSerializer):
    id = serializers.CharField(source='hash_id',read_only=True)
    unread_count = serializers.IntegerField(read_only=True)
    last_message = MessageSerializer(read_only=True,many=False)
    title = serializers.CharField(default="lol",read_only=True)
                     
    class Meta:
        model = models.MessageThread
        fields = ('id','title','last_message','unread_count')
                     
                     
class MessageThreadListSerializer(serializers.ListSerializer):
    child = MessageThreadSerializer()
    many = True
    allow_null = True
