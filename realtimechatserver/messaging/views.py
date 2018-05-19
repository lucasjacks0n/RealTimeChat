# messaging/views.py
                     
from django.http import JsonResponse, HttpResponse
from django.db.models import Count, Q
from django.contrib.auth.decorators import login_required
from django.views.decorators.csrf import csrf_exempt
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer

from . import models
from . import serializers
from userauth import models as userauth_models
                     
                     
@login_required
def load_inbox(request):
    """Load user inbox threads
                     
     - Retrieve all of the threads that includes the user in the clients field.
     - count number of unread messages using related name receipts containing user
     - returns {"threads":[thread]}
    """
    threads = models.MessageThread.objects.filter(clients=request.user).annotate(
        unread_count=Count('receipts',filter=Q(receipts__recipient=request.user))
    )
    thread_data = serializers.MessageThreadListSerializer(threads).data
    return JsonResponse({'threads':thread_data})


@login_required
def load_messages(request):
    """Load messages from thread
                     
     - Load 30 messages by default. 
     - The 'before' parameter will load the previous 30 messages relative to the date.
     - returns json {messages:[message], end:bool}
    """
    thread = models.MessageThread.objects.get(hash_id=request.GET['id'])
    # make sure we are part of this chat before we read the messages
    if not request.user in thread.clients.all():
        return HttpResponse(status=403)
    # query for messages filter
    q = [Q(thread=thread)]
    if 'before' in request.GET:
        q.append(Q(date__lt=int(request.GET['before'])))
    # query messages matching filter
    messages = models.Message.objects.filter(*q).order_by('-id')
    messages_data = serializers.MessageListSerializer(messages[:30]).data
    # mark any unread messages in chat as read
    thread.mark_read(request.user)
    return JsonResponse({"messages":messages_data,"end":messages.count() <= 30})


@login_required
@csrf_exempt
def add_chatroom(request):
    """Add user to chatroom
                          
     - create thread if existing one with title does not exist
     - user is added to the chat as well as the channel_layer group using the channel_name
       specified in the session.
    """
    title = request.POST['title'].strip()
    # get or create thread
    if models.MessageThread.objects.filter(title=title).exists():
        thread = models.MessageThread.objects.get(title=title)
    else:
        thread = models.MessageThread(title=title)
        thread.save()
    # add user to client if not added already
    if not request.user in thread.clients.all():
        thread.clients.add(request.user)
        channel_layer = get_channel_layer()
        if 'channel_name' in request.session:
            # add user's channel layer to thread group
            async_to_sync(channel_layer.group_add)(thread.hash_id,request.session['channel_name'])
    return HttpResponse(status=200)
