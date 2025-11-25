import redis

class RedisMemory:
    def __init__(self, host="localhost", port=6379):
        self.redis_client = redis.Redis(host=host, port=port)

    def get(self, key):
        return self.redis_client.get(key)

    def set(self, key, value):
        self.redis_client.setex(key, 3600, value)