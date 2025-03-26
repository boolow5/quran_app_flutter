package controllers

import (
	"fmt"
	"strings"

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

	bookmarks, err := models.GetBookmarksForUser(c.Request.Context(), models.MySQLDB, userID)
	if err != nil {
		fmt.Printf("[controllers.GetBookmarks] Error getting bookmarks: %v\n", err)
		c.JSON(500, gin.H{
			"error": err.Error(),
		})
		return
	}

	if bookmarks == nil {
		bookmarks = []models.Bookmark{}
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
	err = bookmark.Save(c.Request.Context(), models.MySQLDB)
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

	pageNumberStr, ok := c.Params.Get("pageNumber")
	if !ok {
		fmt.Printf("[controllers.RemoveBookmark] pageNumber not found\n")
		c.JSON(400, gin.H{
			"error": "pageNumber not found",
		})
		return
	}

	pageNumbers := []string{}

	if strings.Contains(pageNumberStr, ",") {
		pageNumbers = strings.Split(pageNumberStr, ",")
	} else {
		pageNumbers = append(pageNumbers, pageNumberStr)
	}

	fmt.Printf("[controllers.RemoveBookmark] pageNumbers: %v\t pageNumberStr: %v\n", pageNumbers, pageNumberStr)

	errMsgs := []string{}

	for _, p := range pageNumbers {
		err := models.RemoveBookmarkForUser(c.Request.Context(), models.MySQLDB, userID, p)
		if err != nil {
			fmt.Printf("[controllers.RemoveBookmark] Error removing bookmark: %v\n", err)
			errMsgs = append(errMsgs, err.Error())
		} else {
			fmt.Printf("[controllers.RemoveBookmark] Bookmark for page %s removed successfully\n", p)
		}
	}

	if len(errMsgs) > 0 {
		c.JSON(500, gin.H{
			"error": strings.Join(errMsgs, ", "),
		})
		return
	}

	c.JSON(200, gin.H{
		"success": true,
		"message": "Bookmark removed successfully",
	})
}
