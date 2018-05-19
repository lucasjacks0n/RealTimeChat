# userauth/models.py
                     
from django.db import models
from django.contrib.auth.models import AbstractUser
                     
from realtimechatserver import helper
                     
                     
class User(AbstractUser):
    """Extend functionality of user"""
                         
    hash_id = models.CharField(max_length=32, default=helper.create_hash, unique=True)