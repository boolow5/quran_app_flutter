package controllers

import (
	"fmt"
	"strconv"
	"time"

	"github.com/boolow5/quran-app-api/models"
	"github.com/boolow5/quran-app-api/streak"
	"github.com/gin-gonic/gin"
)

func RecordReadingEvent(c *gin.Context) {
	userIDStr, ok := c.MustGet("db_user_id").(string)
	if !ok {
		fmt.Printf("[controllers.GetBookmarks] user_id not found\n")
		c.JSON(400, gin.H{
			"error": "user_id not found",
		})
		return
	}

	userID, err := strconv.ParseUint(userIDStr, 10, 64)
	if err != nil {
		fmt.Printf("[controllers.GetBookmarks] Error parsing user_id: %v\n", err)
		c.JSON(400, gin.H{
			"error": err.Error(),
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

	err = streak.RecordReadingEvent(c.Request.Context(), models.MySQLDB, form)
	if err != nil {
		fmt.Printf("[controllers.GetBookmarks] Error getting bookmarks: %v\n", err)
		c.JSON(500, gin.H{
			"error": err.Error(),
		})
		return
	}

	go func(userID uint64, date time.Time) {
		err := streak.UpdateDailySummary(c.Request.Context(), models.MySQLDB, userID, date)
		if err != nil {
			fmt.Printf("[controllers.GetBookmarks] Error getting bookmarks: %v\n", err)
			return
		}
		fmt.Println("Updated daily summary for user: ", userID)
	}(userID, form.CreatedAt)

	c.JSON(200, gin.H{
		"message": "ok",
		"success": true,
	})
}

func UpdateDailySummary(c *gin.Context) {
	userIDStr, ok := c.MustGet("db_user_id").(string)
	if !ok {
		fmt.Printf("[controllers.GetBookmarks] user_id not found\n")
		c.JSON(400, gin.H{
			"error": "user_id not found",
		})
		return
	}

	userID, err := strconv.ParseUint(userIDStr, 10, 64)
	if err != nil {
		fmt.Printf("[controllers.GetBookmarks] Error parsing user_id: %v\n", err)
		c.JSON(400, gin.H{
			"error": err.Error(),
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

	err = streak.UpdateDailySummary(c.Request.Context(), models.MySQLDB, userID, form.Date)
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

func UpdateStreak(c *gin.Context) {
	userIDStr, ok := c.MustGet("db_user_id").(string)
	if !ok {
		fmt.Printf("[controllers.GetBookmarks] user_id not found\n")
		c.JSON(400, gin.H{
			"error": "user_id not found",
		})
		return
	}

	userID, err := strconv.ParseUint(userIDStr, 10, 64)
	if err != nil {
		fmt.Printf("[controllers.GetBookmarks] Error parsing user_id: %v\n", err)
		c.JSON(400, gin.H{
			"error": err.Error(),
		})
		return
	}

	if userID < 1 {
		fmt.Printf("[controllers.GetBookmarks] Error parsing user_id: %v\n", err)
		c.JSON(400, gin.H{
			"error": err.Error(),
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

	err = streak.UpdateStreak(c.Request.Context(), models.MySQLDB, userID, form.Date, form.Seconds > 300)
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
	userIDStr, ok := c.MustGet("db_user_id").(string)
	if !ok {
		fmt.Printf("[controllers.GetBookmarks] user_id not found\n")
		c.JSON(400, gin.H{
			"error": "user_id not found",
		})
		return
	}

	userID, err := strconv.ParseUint(userIDStr, 10, 64)
	if err != nil {
		fmt.Printf("[controllers.GetBookmarks] Error parsing user_id: %v\n", err)
		c.JSON(400, gin.H{
			"error": err.Error(),
		})
		return
	}

	if userID < 1 {
		fmt.Printf("[controllers.GetBookmarks] Error parsing user_id: %v\n", err)
		c.JSON(400, gin.H{
			"error": err.Error(),
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
