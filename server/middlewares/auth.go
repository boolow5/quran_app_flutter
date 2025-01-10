package middlewares

import (
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/boolow5/quran-app-api/models"
	"github.com/gin-gonic/gin"
)

func JWTAuthentication() gin.HandlerFunc {
	return func(c *gin.Context) {
		if c.Request.Method == "OPTIONS" {
			c.Next()
			return
		}

		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			log.Printf("[middleware] Authorization header not found\n")
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Authorization header is required",
			})
			c.Abort()
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			log.Printf("[middleware] Authorization header format is incorrect\n")
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Authorization header must be in the format: Bearer <token>",
			})
			c.Abort()
			return
		}

		claims, err := models.VerifyJWTToken(os.Getenv("JWT_SECRET"), parts[1])
		if err != nil {
			log.Printf("[middleware] Failed to verify token: %v\n", err)
			c.JSON(http.StatusUnauthorized, map[string]string{
				"error": "Invalid or expired token",
			})
			return
		}

		id, ok := claims["sub"].(string)
		if !ok {
			log.Printf("[middleware] Invalid user id: %T\n", claims["sub"])
			c.JSON(http.StatusUnauthorized, map[string]string{
				"error": "Invalid or expired token",
			})
			return
		}

		// Set user context
		c.Set("user_id", id)
	}
}
