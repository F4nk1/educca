package cache

import (
	"time"

	"github.com/patrickmn/go-cache"
)

const DefaultTTL = 5 * time.Minute

type Cache interface {
	Get(key string) (interface{}, bool)
	Set(key string, value interface{}, duration time.Duration)
	Delete(key string)
	Flush()
}

type SimpleCache struct {
	client *cache.Cache
}

func NewSimpleCache() Cache {
	return &SimpleCache{
		client: cache.New(5*time.Minute, 10*time.Minute),
	}
}

func (c *SimpleCache) Get(key string) (interface{}, bool) {
	return c.client.Get(key)
}

func (c *SimpleCache) Set(key string, value interface{}, duration time.Duration) {
	c.client.Set(key, value, duration)
}

func (c *SimpleCache) Delete(key string) {
	c.client.Delete(key)
}

func (c *SimpleCache) Flush() {
	c.client.Flush()
}
