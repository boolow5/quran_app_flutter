package models

import (
	"github.com/boolow5/quran-app-api/db"
	rdb "github.com/boolow5/redis"
)

var (
	RedisDB *rdb.RedisDB
	MySQLDB *db.MySQLDB
)
