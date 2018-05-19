# userauth/views.py
 
import json
 
from django.http import JsonResponse, HttpResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth import login, logout
from django.contrib.auth import authenticate
 
from rest_framework import status
 
from . import serializers
from . import models
 
 
@csrf_exempt
def auth_login(request):
    """Client attempts to login
 
     - Check for username and password
     - Return serialized user data
    """
    if request.POST:
        username = request.POST['username']
        password = request.POST['password']
        user = authenticate(username=username, password=password)
        if user:
            login(request,user)
            serializer = serializers.UserSerializer(user)
            return JsonResponse(serializer.data)
    else:
        if request.user.is_authenticated:
            serializer = serializers.UserSerializer(request.user)
            return JsonResponse(serializer.data)
    return HttpResponse(status=401)


@csrf_exempt
def signup(request):
    """Client attempts to sign up
 
     - If username does not already exist we create and authenticate new account
    """
    if models.User.objects.filter(username=request.POST['username']).exists():
        return HttpResponse(status=403)
    else:
        u = models.User(username=request.POST['username'])
        u.set_password(request.POST['password'])
        u.save()
        login(request, u)
        serializer = serializers.UserSerializer(u)
        return JsonResponse(serializer.data)


def auth_logout(request):
    """Clears the session """
    logout(request)
    return HttpResponse(status=200)
