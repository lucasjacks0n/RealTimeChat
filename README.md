# RealTimeChat

Implementation of a real-time iOS chat application with Swift and Django

### iOS Setup

cd into realtimechatios
Install the application's dependencies with [CocoaPods](https://cocoapods.org/)

```bash
$ pod install
```

### Server Setup

cd into realtimechatserver
Create and activate a python virtual environment
```bash
$ virtualenv venv
$ source venv/bin/activate
```
Install python dependency packages

```bash
$ pip install -r requirements.txt
```

Install [redis](https://redis.io/topics/quickstart)
Run redis and start server

```bash
$ redis-server &
$ ./manage.py runserver
```
