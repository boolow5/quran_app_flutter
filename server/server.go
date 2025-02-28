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
	"github.com/boolow5/quran-app-api/notifications"
	rdb "github.com/boolow5/redis"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

var (
	Version     = ""
	BuiltAt     = time.Now().Format("2006-01-02 15:04:05")
	BuildCommit = ""
	StartedAt   = time.Now()
)

func main() {
	err := godotenv.Load()
	if err != nil {
		fmt.Println("⚠ Error loading .env file")
	} else {
		fmt.Println("✅ Loaded .env file")
	}

	log.Printf("Starting '%s' server...\n", os.Getenv("APP_NAME"))
	// Just to force the github action to start, without actually doing anything

	// gin.SetMode(gin.ReleaseMode)
	router := gin.Default()

	db := SetupServices()

	controllers.SetupHandlers(router, db)

	go StartCronJobs(db)

	router.Run("0.0.0.0:1140")
}

func SetupServices() db.Database {
	fmt.Printf("Connecting to redis on %s\n", os.Getenv("REDIS_HOST"))
	redisDB, err := rdb.NewRedisDB("", "", 0)
	if err != nil {
		panic(fmt.Sprintf("Failed to connect to redis: %v", err))
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

	notifications.InitFirebase()

	return mysql
}
