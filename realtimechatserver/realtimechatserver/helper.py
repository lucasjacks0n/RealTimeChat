# realtimechatserver/helper.py
                     
import os, time
from binascii import hexlify
                     
                     
def create_hash():
    return str(hexlify(os.urandom(16)), 'ascii')
                     
def time_stamp():
    return int(round(time.time()))
