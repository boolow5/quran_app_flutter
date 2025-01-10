package controllers

import (
	"github.com/boolow5/quran-app-api/models"
	"github.com/gin-gonic/gin"
)

func GetBookmarks(c *gin.Context) {
	userID, ok := c.MustGet("user_id").(string)
	if !ok {
		c.JSON(400, gin.H{
			"error": "user_id not found",
		})
		return
	}

	bookmarks, err := models.GetBookmarksForUser(userID)
	if err != nil {
		c.JSON(500, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(200, bookmarks)
}

func AddBookmark(c *gin.Context) {
	userID, ok := c.MustGet("user_id").(string)
	if !ok {
		c.JSON(400, gin.H{
			"error": "user_id not found",
		})
		return
	}

	var bookmark models.Bookmark
	err := c.ShouldBindJSON(&bookmark)
	if err != nil {
		c.JSON(400, gin.H{
			"error": err.Error(),
		})
		return
	}

	bookmark.UserID = userID
	err = bookmark.Save()
	if err != nil {
		c.JSON(500, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(200, bookmark)
}

func RemoveBookmark(c *gin.Context) {
	userID, ok := c.MustGet("user_id").(string)
	if !ok {
		c.JSON(400, gin.H{
			"error": "user_id not found",
		})
		return
	}

	pageNumber, ok := c.Params.Get("pageNumber")
	if !ok {
		c.JSON(400, gin.H{
			"error": "pageNumber not found",
		})
		return
	}

	err := models.RemoveBookmarkForUser(userID, pageNumber)
	if err != nil {
		c.JSON(500, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(200, gin.H{
		"success": true,
		"message": "Bookmark removed successfully",
	})
}
