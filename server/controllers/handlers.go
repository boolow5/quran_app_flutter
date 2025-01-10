package controllers

import (
	"github.com/boolow5/quran-app-api/middlewares"
	"github.com/gin-gonic/gin"
)

func SetupHandlers(router *gin.Engine) {
	router.SetTrustedProxies([]string{"127.0.0.1:1140", "localhost:1140", ""})
	r := router.Group("/api/v1")

	bookmarks := r.Group("/bookmarks")
	bookmarks.Use(middlewares.JWTAuthentication())
	bookmarks.GET("", GetBookmarks)
	bookmarks.POST("", AddBookmark)
	bookmarks.DELETE("/:id", RemoveBookmark)
}
