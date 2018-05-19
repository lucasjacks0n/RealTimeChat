# realtimechatserver/urls.py
 
from django.contrib import admin
from django.urls import path
from django.conf.urls import include
 
 
urlpatterns = [
    path('admin/', admin.site.urls),
    path('auth/', include('userauth.urls')),
    path('messaging/', include('messaging.urls')),
]