# messaging/urls.py
 
from django.conf.urls import url
from django.urls import path
                     
from . import views
                     
                     
urlpatterns = [
    path('load-inbox',views.load_inbox),
    path('load-messages',views.load_messages),
    path('add-chatroom',views.add_chatroom),
]