package controllers

import (
	"log"

	"github.com/boolow5/quran-app-api/middlewares"
	"github.com/gin-gonic/gin"
)

func SetupHandlers(router *gin.Engine) {
	// Initialize Firebase Auth
	auth, err := middlewares.NewFirebaseAuth("./meezansync-95a7c-firebase-adminsdk-plq74-147577be30.json")
	if err != nil {
		log.Fatalf("Error initializing Firebase Auth: %v", err)
	}
	router.SetTrustedProxies([]string{"127.0.0.1:1140", "localhost:1140", ""})
	r := router.Group("/api/v1")
	r.Use(auth.Middleware())

	bookmarks := r.Group("/bookmarks")
	// bookmarks.Use(middlewares.JWTAuthentication())
	bookmarks.GET("", GetBookmarks)
	bookmarks.POST("", AddBookmark)
	bookmarks.DELETE("/:id", RemoveBookmark)
}
