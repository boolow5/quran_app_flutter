package controllers

import (
	"fmt"
	"time"

	"github.com/boolow5/quran-app-api/models"
	"github.com/boolow5/quran-app-api/streak"
	"github.com/gin-gonic/gin"
)

func GetRecentPages(c *gin.Context) {
	userID, ok := c.MustGet("db_user_id").(uint64)
	if !ok {
		fmt.Printf("[controllers.GetBookmarks] user_id not found\n")
		c.JSON(400, gin.H{
			"error": "user_id not found",
		})
		return
	}

	pages, err := streak.GetRecentPages(c.Request.Context(), models.MySQLDB, userID, 3)
	if err != nil {
		fmt.Printf("[controllers.GetRecentPages] Error getting recent pages: %v\n", err)
		c.JSON(500, gin.H{
			"error": err.Error(),
		})
		return
	}

	if pages == nil {
		pages = []streak.RecentPage{}
	}

	c.JSON(200, pages)
}

func RecordReadingEvent(c *gin.Context) {
	userID, ok := c.MustGet("db_user_id").(uint64)
	if !ok {
		fmt.Printf("[controllers.GetBookmarks] user_id not found\n")
		c.JSON(400, gin.H{
			"error": "user_id not found",
		})
		return
	}

	form := streak.ReadingEvent{}
	if err := c.ShouldBind(&form); err != nil {
		fmt.Printf("[controllers.GetBookmarks] Error binding JSON: %v\n", err)
		c.JSON(400, gin.H{
			"error": err.Error(),
		})
		return
	}

	form.UserID = userID
	form.CreatedAt = time.Now()

	err := streak.RecordReadingEvent(c.Request.Context(), models.MySQLDB, form)
	if err != nil {
		fmt.Printf("[controllers.GetBookmarks] Error getting bookmarks: %v\n", err)
		c.JSON(500, gin.H{
			"error": err.Error(),
		})
		return
	}

	// go func(userID uint64, date time.Time) {
	totalSeconds, err := streak.UpdateDailySummary(c.Request.Context(), models.MySQLDB, userID, form.CreatedAt)
	if err != nil {
		fmt.Printf("[controllers.GetBookmarks] Error getting bookmarks: %v\n", err)
		return
	}
	fmt.Println("Updated daily summary for user: ", userID)
	// }(userID, form.CreatedAt)

	percentage := float64(totalSeconds) / streak.MinReadingTimeThreshold * 100
	if percentage > 100 {
		percentage = 100
	}

	c.JSON(200, gin.H{
		"message":         "ok",
		"success":         true,
		"total_seconds":   totalSeconds,
		"percentage_done": percentage,
	})
}

func UpdateDailySummary(c *gin.Context) {
	userID, ok := c.MustGet("db_user_id").(uint64)
	if !ok {
		fmt.Printf("[controllers.GetBookmarks] user_id not found\n")
		c.JSON(400, gin.H{
			"error": "user_id not found",
		})
		return
	}

	form := struct {
		Date time.Time `json:"date"`
	}{}
	if err := c.ShouldBind(&form); err != nil {
		fmt.Printf("[controllers.GetBookmarks] Error binding JSON: %v\n", err)
		c.JSON(400, gin.H{
			"error": err.Error(),
		})
		return
	}

	totalSeconds, err := streak.UpdateDailySummary(c.Request.Context(), models.MySQLDB, userID, form.Date)
	if err != nil {
		fmt.Printf("[controllers.GetBookmarks] Error getting bookmarks: %v\n", err)
		c.JSON(500, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(200, gin.H{
		"message":       "ok",
		"success":       true,
		"total_seconds": totalSeconds,
	})
}

func UpdateStreak(c *gin.Context) {
	userID, ok := c.MustGet("db_user_id").(uint64)
	if !ok {
		fmt.Printf("[controllers.GetBookmarks] user_id not found\n")
		c.JSON(400, gin.H{
			"error": "user_id not found",
		})
		return
	}

	if userID < 1 {
		fmt.Printf("[controllers.GetBookmarks] Invalid user ID: %v\n", userID)
		c.JSON(400, gin.H{
			"error": "Invalid user ID",
		})
		return
	}

	form := struct {
		Date    time.Time `json:"date"`
		Seconds int       `json:"seconds"`
	}{}
	if err := c.ShouldBind(&form); err != nil {
		fmt.Printf("[controllers.GetBookmarks] Error binding JSON: %v\n", err)
		c.JSON(400, gin.H{
			"error": err.Error(),
		})
		return
	}

	err := streak.UpdateStreak(c.Request.Context(), models.MySQLDB, userID, form.Date, form.Seconds > 300)
	if err != nil {
		fmt.Printf("[controllers.GetBookmarks] Error getting bookmarks: %v\n", err)
		c.JSON(500, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(200, gin.H{
		"message": "ok",
		"success": true,
	})
}

func GetUserStreak(c *gin.Context) {
	userID, ok := c.MustGet("db_user_id").(uint64)
	if !ok {
		fmt.Printf("[controllers.GetBookmarks] user_id not found\n")
		c.JSON(400, gin.H{
			"error": "user_id not found",
		})
		return
	}

	if userID < 1 {
		fmt.Printf("[controllers.GetBookmarks] Invalid user ID: %v\n", userID)
		c.JSON(400, gin.H{
			"error": "Invalid user ID",
		})
		return
	}

	streak, err := streak.GetUserStreak(c.Request.Context(), models.MySQLDB, userID)
	if err != nil {
		fmt.Printf("[controllers.GetBookmarks] Error getting bookmarks: %v\n", err)
		c.JSON(500, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(200, streak)
}
