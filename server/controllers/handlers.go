package controllers

import (
	"log"

	"github.com/boolow5/quran-app-api/db"
	"github.com/boolow5/quran-app-api/middlewares"
	"github.com/gin-gonic/gin"
)

func SetupHandlers(router *gin.Engine, db db.Database) {
	// Initialize Firebase Auth
	// "./meezansync-95a7c-firebase-adminsdk-plq74-147577be30.json"
	auth, err := middlewares.NewFirebaseAuth("")
	if err != nil {
		log.Fatalf("Error initializing Firebase Auth: %v", err)
	}
	router.SetTrustedProxies([]string{"127.0.0.1:1140", "localhost:1140", ""})

	r := router.Group("/api/v1")

	r.Use(middlewares.Cors())

	authenicated := r.Group("")
	authenicated.Use(auth.Middleware(db))

	// recent pages
	recentPages := authenicated.Group("/recent-pages")
	recentPages.GET("", GetRecentPages)

	bookmarks := authenicated.Group("/bookmarks")
	// bookmarks.Use(middlewares.JWTAuthentication())
	bookmarks.GET("", GetBookmarks)
	bookmarks.POST("", AddBookmark)
	bookmarks.DELETE("/:pageNumber", RemoveBookmark)

	// streak handlers
	streaks := authenicated.Group("/streaks")
	streaks.GET("", GetUserStreak)
	streaks.POST("/read-event", RecordReadingEvent)
	streaks.PUT("", UpdateDailySummary)

	// /api/v1/login
	authenicated.POST("/login", auth.Login(db))

	// notifications
	notifications := authenicated.Group("/notifications")
	notifications.POST("/device-fcm-token", CreateOrUpdateFCMToken)

	// // handle all OPTIONS requests
	// r.OPTIONS("/*any", func(c *gin.Context) {
	// 	headerOrigin := c.Request.Header.Get("Origin")
	// 	if headerOrigin == "" {
	// 		c.AbortWithStatus(204)
	// 		return
	// 	}

	// 	if middlewares.IsAllowedOrigin(headerOrigin) {
	// 		fmt.Printf("[any] Origin allowed: %s\n", headerOrigin)
	// 		c.Writer.Header().Set("Access-Control-Allow-Origin", headerOrigin)
	// 	} else {
	// 		fmt.Printf("[any] Origin not allowed: '%s'\n", headerOrigin)
	// 		c.AbortWithStatus(403)
	// 		return
	// 	}

	// 	fmt.Printf("[any] OPTIONS request\n")
	// 	c.AbortWithStatus(204)
	// })
}
