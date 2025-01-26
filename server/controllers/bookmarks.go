package controllers

import (
	"fmt"

	"github.com/boolow5/quran-app-api/models"
	"github.com/gin-gonic/gin"
)

func GetBookmarks(c *gin.Context) {
	userID, ok := c.MustGet("user_id").(string)
	if !ok {
		fmt.Printf("[controllers.GetBookmarks] user_id not found\n")
		c.JSON(400, gin.H{
			"error": "user_id not found",
		})
		return
	}

	bookmarks, err := models.GetBookmarksForUser(c.Request.Context(), userID)
	if err != nil {
		fmt.Printf("[controllers.GetBookmarks] Error getting bookmarks: %v\n", err)
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
		fmt.Printf("[controllers.AddBookmark] user_id not found\n")
		c.JSON(400, gin.H{
			"error": "user_id not found",
		})
		return
	}

	var bookmark models.Bookmark
	err := c.ShouldBind(&bookmark)
	if err != nil {
		fmt.Printf("[controllers.AddBookmark] Error binding JSON: %v\n", err)
		c.JSON(400, gin.H{
			"error": err.Error(),
		})
		return
	}

	bookmark.UserID = userID
	err = bookmark.Save(c.Request.Context())
	if err != nil {
		fmt.Printf("[controllers.AddBookmark] Error saving bookmark: %v\n", err)
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
		fmt.Printf("[controllers.RemoveBookmark] user_id not found\n")
		c.JSON(400, gin.H{
			"error": "user_id not found",
		})
		return
	}

	pageNumber, ok := c.Params.Get("pageNumber")
	if !ok {
		fmt.Printf("[controllers.RemoveBookmark] pageNumber not found\n")
		c.JSON(400, gin.H{
			"error": "pageNumber not found",
		})
		return
	}

	err := models.RemoveBookmarkForUser(c.Request.Context(), userID, pageNumber)
	if err != nil {
		fmt.Printf("[controllers.RemoveBookmark] Error removing bookmark: %v\n", err)
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
