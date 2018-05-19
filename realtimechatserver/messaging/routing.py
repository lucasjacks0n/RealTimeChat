# messaging/routing.py
                     
from django.urls import path
                     
from . import consumers
                     
                     
websocket_urlpatterns = [
    path('connect',consumers.ChatConsumer),
]