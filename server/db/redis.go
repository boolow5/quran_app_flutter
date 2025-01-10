package db

import (
	"context"
	"os"
	"strconv"
	"time"

	"github.com/redis/go-redis/v9"
)

var redisCtx = context.Background()

type IRedisDB interface {
	// Get keys gets all keys matching pattern.
	GetKeys(pattern string) ([]string, error)

	// Get gets the value of a key.
	Get(key string) (string, error)

	// Set sets the value of a key.
	Set(key string, value interface{}) error

	// SetEx sets the value of a key with an expiration time.
	SetEx(key string, value interface{}, expiration int) error

	// Del deletes a key.
	Del(keys ...string) error

	// Exists checks if a key exists.
	Exists(key string) (int64, error)

	// Expire sets a key's time to live in seconds.
	Expire(key string, expiration int) error

	// Incr increments a key.
	Incr(key string) error

	// IncrBy increments a key by a value.
	IncrBy(key string, value int) error

	// Decr decrements a key.
	Decr(key string) error

	// DecrBy decrements a key by a value.
	DecrBy(key string, value int) error

	// HGet gets the value of a hash field.
	HGet(key string, field string) (string, error)

	// HSet sets the value of a hash field.
	HSet(key string, field string, value interface{}) error

	// HDel deletes a hash field.
	HDel(key string, field string) error

	// HExists checks if a hash field exists.
	HExists(key string, field string) (bool, error)

	// HGetAll gets all the fields and values in a hash.
	HGetAll(key string) (map[string]string, error)

	// HIncr increments a hash field.
	HIncr(key string, field string) error

	// HIncrBy increments a hash field by a value.
	HIncrBy(key string, field string, value int) error

	// HDecr decrements a hash field.
	HDecr(key string, field string) error

	// HDecrBy decrements a hash field by a value.
	HDecrBy(key string, field string, value int) error

	// LPush inserts an element at the head of the list.
	LPush(key string, value interface{}) error

	// LRange gets a range of elements from a list.
	LRange(key string, start int, stop int) ([]string, error)

	// LLen gets the length of a list.
	LLen(key string) (int64, error)

	// LPop removes and returns the first element of a list.
	LPop(key string) (string, error)

	// RPush inserts an element at the tail of the list.
	RPush(key string, value interface{}) error

	// RPop removes and returns the last element of a list.
	RPop(key string) (string, error)

	// SAdd adds a member to a set.
	SAdd(key string, member interface{}) error

	// SRem removes a member from a set.
	SRem(key string, member interface{}) error

	// SIsMember checks if a member is in a set.
	SIsMember(key string, member interface{}) (bool, error)
}

type RedisDB struct {
	client *redis.Client
}

func NewRedisDB(uri, password string, defaultDb int) (*RedisDB, error) {
	if uri == "" {
		redisHost := os.Getenv("REDIS_HOST")
		if redisHost == "" {
			redisHost = "localhost"
		}

		redisPort := os.Getenv("REDIS_PORT")
		if redisPort == "" {
			redisPort = "6379"
		}

		uri = redisHost + ":" + redisPort
	}

	if password == "" {
		password = os.Getenv("REDIS_PASSWORD")
	}

	var err error

	if defaultDb == 0 {
		defaultDb, err = strconv.Atoi(os.Getenv("REDIS_DEFAULT_DB"))
		if err != nil {
			defaultDb = 0
		}
	}

	client := redis.NewClient(&redis.Options{
		Addr:     uri,
		Password: password,
		DB:       defaultDb,
	})

	_, err = client.Ping(redisCtx).Result()
	if err != nil {
		return nil, err
	}

	db := &RedisDB{
		client: client,
	}

	return db, nil
}

func (r *RedisDB) Ping() (string, error) {
	return r.client.Ping(redisCtx).Result()
}

func (r *RedisDB) GetKeys(pattern string) ([]string, error) {
	return r.client.Keys(redisCtx, pattern).Result()
}

func (r *RedisDB) GetKeyExpiry(pattern string) (time.Duration, error) {
	return r.client.TTL(redisCtx, pattern).Result()
}

func (r *RedisDB) Get(key string) (string, error) {
	return r.client.Get(redisCtx, key).Result()
}

func (r *RedisDB) Set(key string, value interface{}) error {
	return r.client.Set(redisCtx, key, value, 0).Err()
}

// SetEx takes key, value and expiration in seconds
func (r *RedisDB) SetEx(key string, value interface{}, expiration int) error {
	return r.client.Set(redisCtx, key, value, time.Duration(expiration)*time.Second).Err()
}

func (r *RedisDB) Del(keys ...string) error {
	return r.client.Del(redisCtx, keys...).Err()
}

func (r *RedisDB) Exists(key string) (int64, error) {
	return r.client.Exists(redisCtx, key).Result()
}

func (r *RedisDB) Expire(key string, expiration int) error {
	return r.client.Expire(redisCtx, key, time.Duration(expiration)*time.Second).Err()
}

func (r *RedisDB) Incr(key string) error {
	return r.client.Incr(redisCtx, key).Err()
}

func (r *RedisDB) IncrBy(key string, value int) error {
	return r.client.IncrBy(redisCtx, key, int64(value)).Err()
}

func (r *RedisDB) Decr(key string) error {
	return r.client.Decr(redisCtx, key).Err()
}

func (r *RedisDB) DecrBy(key string, value int) error {
	return r.client.DecrBy(redisCtx, key, int64(value)).Err()
}

func (r *RedisDB) HGet(key string, field string) (string, error) {
	return r.client.HGet(redisCtx, key, field).Result()
}

func (r *RedisDB) HSet(key string, field string, value interface{}) error {
	return r.client.HSet(redisCtx, key, field, value).Err()
}

func (r *RedisDB) HDel(key string, field string) error {
	return r.client.HDel(redisCtx, key, field).Err()
}

func (r *RedisDB) HExists(key string, field string) (bool, error) {
	return r.client.HExists(redisCtx, key, field).Result()
}

func (r *RedisDB) HGetAll(key string) (map[string]string, error) {
	return r.client.HGetAll(redisCtx, key).Result()
}

func (r *RedisDB) HIncr(key string, field string) error {
	return r.client.HIncrBy(redisCtx, key, field, 1).Err()
}

func (r *RedisDB) HIncrBy(key string, field string, value int) error {
	return r.client.HIncrBy(redisCtx, key, field, int64(value)).Err()
}

func (r *RedisDB) HDecr(key string, field string) error {
	return r.client.HIncrBy(redisCtx, key, field, -1).Err()
}

func (r *RedisDB) HDecrBy(key string, field string, value int) error {
	return r.client.HIncrBy(redisCtx, key, field, int64(-value)).Err()
}

func (r *RedisDB) LPush(key string, value interface{}) error {
	return r.client.LPush(redisCtx, key, value).Err()
}

func (r *RedisDB) LRange(key string, start int, stop int) ([]string, error) {
	return r.client.LRange(redisCtx, key, int64(start), int64(stop)).Result()
}

func (r *RedisDB) LLen(key string) (int64, error) {
	return r.client.LLen(redisCtx, key).Result()
}

func (r *RedisDB) LPop(key string) (string, error) {
	return r.client.LPop(redisCtx, key).Result()
}

func (r *RedisDB) RPush(key string, value interface{}) error {
	return r.client.RPush(redisCtx, key, value).Err()
}

func (r *RedisDB) RPop(key string) (string, error) {
	return r.client.RPop(redisCtx, key).Result()
}

func (r *RedisDB) SAdd(key string, member interface{}) error {
	return r.client.SAdd(redisCtx, key, member).Err()
}

func (r *RedisDB) SRem(key string, member interface{}) error {
	return r.client.SRem(redisCtx, key, member).Err()
}

func (r *RedisDB) SIsMember(key string, member interface{}) (bool, error) {
	return r.client.SIsMember(redisCtx, key, member).Result()
}
