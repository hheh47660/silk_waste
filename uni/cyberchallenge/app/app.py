import time
import redis
from flask import Flask
app = Flask(__name__)
cache = redis.Redis(host='db', port=6379) # 'db' matches the service name!
@app.route('/')
def hello():
 count = cache.incr('hits')
 return f'Hello! This page has been viewed {count} times.\n'
if __name__ == "__main__":
 app.run(host="0.0.0.0", port=5000)
