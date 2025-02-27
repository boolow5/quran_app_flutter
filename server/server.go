package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/boolow5/quran-app-api/controllers"
	"github.com/boolow5/quran-app-api/db"
	"github.com/boolow5/quran-app-api/models"
	"github.com/boolow5/quran-app-api/streak"
	rdb "github.com/boolow5/redis"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	log.Printf("Starting %s server...\n", os.Getenv("APP_NAME"))

	// gin.SetMode(gin.ReleaseMode)
	router := gin.Default()

	db := SetupServices()

	controllers.SetupHandlers(router, db)

	go ProcessDailyStreaks()

	router.Run("0.0.0.0:1140")
}

func SetupServices() db.Database {
	redisDB, err := rdb.NewRedisDB("", "", 0)
	if err != nil {
		panic(err)
	}
	if redisDB == nil {
		panic("RedisDB is nil")
	}
	fmt.Printf("Connected to Redis\n")
	models.RedisDB = redisDB
	ctx := context.Background()
	models.RedisDB.Set(ctx, "test", "test")
	time.Sleep(1 * time.Second)
	val, err := models.RedisDB.Get(ctx, "test")
	if err != nil {
		fmt.Printf("Error getting value: %v\n", err)
		panic(err)
	}
	fmt.Printf("Got value: %s\n", val)

	mysql, err := db.NewMysqlDB(os.Getenv("QURAN_API_MYSQL_URL"))
	if err != nil {
		panic(err)
	}
	if mysql == nil {
		panic("MySQLDB is nil")
	}
	fmt.Printf("Connected to MySQL\n")
	models.MySQLDB = mysql

	db.InitTables(mysql)
	return mysql
}

func ProcessDailyStreaks() {
	for {
		streak.ProcessDailyStreaks(context.Background(), models.MySQLDB)

		time.Sleep(24 * time.Hour)
	}
}
