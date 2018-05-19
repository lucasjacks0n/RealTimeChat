# userauth/serializers.py
                     
from rest_framework import serializers
 
from . import models
                     
                     
class UserSerializer(serializers.ModelSerializer):
    id = serializers.CharField(source='hash_id',read_only=True)
                     
    class Meta:
        model = models.User
        fields = ('id','username')
