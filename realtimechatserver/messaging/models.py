# messaging/models.py
 
from django.db import models
                     
from realtimechatserver import helper
                     
                     
class MessageThread(models.Model):
    """Thread for messages
               
    Consists of:
     - hash id
     - ManyToManyField containing clients participating in the thread
     - ForeignKey last_message to last Message in thread
    Brief:
     - mark_read marks all messages read for a particular user
     - add_message_text adds a message sent by sender
    """
    hash_id = models.CharField(max_length=32,default=helper.create_hash,unique=True)
    title = models.CharField(max_length=64)
    clients = models.ManyToManyField('userauth.User',blank=True)
    last_message = models.ForeignKey('messaging.Message',null=True,blank=True,on_delete=models.SET_NULL)
 
    def mark_read(self,user):
        UnreadReceipt.objects.filter(recipient=user,thread=self).delete()
 
    def add_message_text(self,text,sender):
        """User sends text to the chat
         - creates new message with foreign key to self
         - adds unread receipt for each user
         - returns instance of new message
        """
        new_message = Message(text=text,sender=sender,thread=self)
        new_message.save()
        self.last_message = new_message
        self.save()
        for c in self.clients.exclude(id=sender.id):
            UnreadReceipt.objects.create(recipient=c,thread=self,message=new_message)
        return new_message
        

class Message(models.Model):
    """Thread Message
     
    Consists of:
     - hash id
     - date sent integer timestamp
     - CharField for text message
     - ForeignKey to sender
     - ForeignKey to thread it was sent to
    """
    hash_id = models.CharField(max_length=32,default=helper.create_hash,unique=True)
    date = models.IntegerField(default=helper.time_stamp)
    text = models.CharField(max_length=1024)
    thread = models.ForeignKey('messaging.MessageThread',on_delete=models.CASCADE,related_name='messages')
    sender = models.ForeignKey('userauth.User',on_delete=models.SET_NULL,null=True)


class UnreadReceipt(models.Model):
    """Unread receipt for unread messages
          
    Consists of:           
     - date sent integer timestamp
     - ForeignKey to corresponding Message
     - ForeignKey to Thread
     - ForeignKey to User who has not yet seen message

    Brief:
     - deleted when a user loads thread messages or when they respond with
       the 'read' message over websocket connection
    """
    date = models.IntegerField(default=helper.time_stamp)
    message = models.ForeignKey('messaging.Message',on_delete=models.CASCADE,related_name='receipts')
    thread = models.ForeignKey('messaging.MessageThread',on_delete=models.CASCADE,related_name='receipts')
    recipient = models.ForeignKey('userauth.User',on_delete=models.CASCADE,related_name='receipts')

