package main

import (
	"github.com/boolow5/quran-app-api/controllers"
	"github.com/boolow5/quran-app-api/db"
	"github.com/boolow5/quran-app-api/models"
	"github.com/gin-gonic/gin"
)

func main() {
	// gin.SetMode(gin.ReleaseMode)
	router := gin.Default()

	SetupServices()

	controllers.SetupHandlers(router)

	router.Run("0.0.0.0:1140")
}

func SetupServices() {
	redisDB, err := db.NewRedisDB("", "", 0)
	if err != nil {
		panic(err)
	}
	models.RedisDB = redisDB
}
