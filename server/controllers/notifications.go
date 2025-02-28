package controllers

import (
	"fmt"

	"github.com/boolow5/quran-app-api/models"
	"github.com/gin-gonic/gin"
)

func CreateOrUpdateFCMToken(c *gin.Context) {
	userID, ok := c.MustGet("db_user_id").(uint64)
	if !ok {
		fmt.Printf("[controllers.GetBookmarks] user_id not found\n")
		c.JSON(400, gin.H{
			"error": "user_id not found",
		})
		return
	}

	form := models.UserDevice{}
	if err := c.ShouldBind(&form); err != nil {
		fmt.Printf("[controllers.GetBookmarks] Error binding JSON: %v\n", err)
		c.JSON(400, gin.H{
			"error": err.Error(),
		})
		return
	}

	form.UserID = userID

	err := models.CreateOrUpdateFCMToken(c.Request.Context(), models.MySQLDB, form)
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
