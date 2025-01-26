package db

import (
	"context"
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/redis/go-redis/v9"
)

var (
	keyPrefix = ""
	// redisCtx  = context.Background()
)

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
	keyPrefix = os.Getenv("APP_NAME")
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

	_, err = client.Ping(context.Background()).Result()
	if err != nil {
		return nil, err
	}

	db := &RedisDB{
		client: client,
	}

	return db, nil
}

func addPrefix(key string) string {
	if keyPrefix == "" {
		return key
	}

	if strings.HasPrefix(key, keyPrefix) {
		return key
	}

	normalizedPrefix := keyPrefix
	if !strings.HasSuffix(normalizedPrefix, ":") {
		normalizedPrefix += ":"
	}

	return normalizedPrefix + key
}

func (r *RedisDB) Ping() (string, error) {
	return r.client.Ping(context.Background()).Result()
}

func (r *RedisDB) GetKeys(ctx context.Context, pattern string) ([]string, error) {
	return r.client.Keys(ctx, addPrefix(pattern)).Result()
}

func (r *RedisDB) GetKeyExpiry(ctx context.Context, pattern string) (time.Duration, error) {
	return r.client.TTL(ctx, addPrefix(pattern)).Result()
}

func (r *RedisDB) Get(ctx context.Context, key string) (string, error) {
	fmt.Printf("[RedisDB.Get] key: %s\n", key)
	if r.client == nil {
		return "", errors.New("redis client is nil")
	}
	return r.client.Get(ctx, addPrefix(key)).Result()
}

func (r *RedisDB) Set(ctx context.Context, key string, value interface{}) error {
	return r.client.Set(ctx, addPrefix(key), value, 0).Err()
}

// SetEx takes key, value and expiration in seconds
func (r *RedisDB) SetEx(ctx context.Context, key string, value interface{}, expiration int) error {
	return r.client.Set(ctx, addPrefix(key), value, time.Duration(expiration)*time.Second).Err()
}

func (r *RedisDB) Del(ctx context.Context, keys ...string) error {
	for i, key := range keys {
		keys[i] = addPrefix(key)
	}

	return r.client.Del(ctx, keys...).Err()
}

func (r *RedisDB) Exists(ctx context.Context, key string) (int64, error) {
	return r.client.Exists(ctx, addPrefix(key)).Result()
}

func (r *RedisDB) Expire(ctx context.Context, key string, expiration int) error {
	return r.client.Expire(ctx, addPrefix(key), time.Duration(expiration)*time.Second).Err()
}

func (r *RedisDB) Incr(ctx context.Context, key string) error {
	return r.client.Incr(ctx, addPrefix(key)).Err()
}

func (r *RedisDB) IncrBy(ctx context.Context, key string, value int) error {
	return r.client.IncrBy(ctx, addPrefix(key), int64(value)).Err()
}

func (r *RedisDB) Decr(ctx context.Context, key string) error {
	return r.client.Decr(ctx, addPrefix(key)).Err()
}

func (r *RedisDB) DecrBy(ctx context.Context, key string, value int) error {
	return r.client.DecrBy(ctx, addPrefix(key), int64(value)).Err()
}

func (r *RedisDB) HGet(ctx context.Context, key string, field string) (string, error) {
	return r.client.HGet(ctx, addPrefix(key), field).Result()
}

func (r *RedisDB) HSet(ctx context.Context, key string, field string, value interface{}) error {
	return r.client.HSet(ctx, addPrefix(key), field, value).Err()
}

func (r *RedisDB) HDel(ctx context.Context, key string, field string) error {
	return r.client.HDel(ctx, addPrefix(key), field).Err()
}

func (r *RedisDB) HExists(ctx context.Context, key string, field string) (bool, error) {
	return r.client.HExists(ctx, addPrefix(key), field).Result()
}

func (r *RedisDB) HGetAll(ctx context.Context, key string) (map[string]string, error) {
	return r.client.HGetAll(ctx, addPrefix(key)).Result()
}

func (r *RedisDB) HIncr(ctx context.Context, key string, field string) error {
	return r.client.HIncrBy(ctx, addPrefix(key), field, 1).Err()
}

func (r *RedisDB) HIncrBy(ctx context.Context, key string, field string, value int) error {
	return r.client.HIncrBy(ctx, addPrefix(key), field, int64(value)).Err()
}

func (r *RedisDB) HDecr(ctx context.Context, key string, field string) error {
	return r.client.HIncrBy(ctx, addPrefix(key), field, -1).Err()
}

func (r *RedisDB) HDecrBy(ctx context.Context, key string, field string, value int) error {
	return r.client.HIncrBy(ctx, addPrefix(key), field, int64(-value)).Err()
}

func (r *RedisDB) LPush(ctx context.Context, key string, value interface{}) error {
	return r.client.LPush(ctx, addPrefix(key), value).Err()
}

func (r *RedisDB) LRange(ctx context.Context, key string, start int, stop int) ([]string, error) {
	return r.client.LRange(ctx, addPrefix(key), int64(start), int64(stop)).Result()
}

func (r *RedisDB) LLen(ctx context.Context, key string) (int64, error) {
	return r.client.LLen(ctx, addPrefix(key)).Result()
}

func (r *RedisDB) LPop(ctx context.Context, key string) (string, error) {
	return r.client.LPop(ctx, addPrefix(key)).Result()
}

func (r *RedisDB) RPush(ctx context.Context, key string, value interface{}) error {
	return r.client.RPush(ctx, addPrefix(key), value).Err()
}

func (r *RedisDB) RPop(ctx context.Context, key string) (string, error) {
	return r.client.RPop(ctx, addPrefix(key)).Result()
}

func (r *RedisDB) SAdd(ctx context.Context, key string, member interface{}) error {
	return r.client.SAdd(ctx, addPrefix(key), member).Err()
}

func (r *RedisDB) SRem(ctx context.Context, key string, member interface{}) error {
	return r.client.SRem(ctx, addPrefix(key), member).Err()
}

func (r *RedisDB) SIsMember(ctx context.Context, key string, member interface{}) (bool, error) {
	return r.client.SIsMember(ctx, addPrefix(key), member).Result()
}
