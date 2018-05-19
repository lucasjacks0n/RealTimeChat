# userauth/urls.py
                     
from django.urls import path
                     
from userauth import views
                     
                     
urlpatterns = [
    path('login',views.auth_login),
    path('logout',views.auth_logout),
    path('signup',views.signup),
]
