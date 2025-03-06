package middlewares

import (
	"fmt"
	"strings"

	"github.com/gin-gonic/gin"
)

var (
	AllowedOrigins = []string{
		"quran-api.mahad.dev",
		"localhost:4580",
		"127.0.0.1:4580",
		"192.168.100.50:1140",
	}
)

func Cors() gin.HandlerFunc {
	return func(c *gin.Context) {
		headerOrigin := c.Request.Header.Get("Origin")
		if headerOrigin == "" {
			c.Next()
			return
		}

		fmt.Printf("[middleware] Origin: '%s'\n", headerOrigin)
		if IsAllowedOrigin(headerOrigin) {
			fmt.Printf("[middleware] Origin allowed: %s\n", headerOrigin)
			c.Writer.Header().Set("Access-Control-Allow-Origin", c.Request.Header.Get("Origin"))
		} else {
			fmt.Printf("[middleware] Origin not allowed: %s\n", headerOrigin)
			c.AbortWithStatus(403)
			return
		}

		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Accept, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization")
		if c.Request.Method == "OPTIONS" {
			fmt.Printf("[middleware] OPTIONS request\n")
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	}
}

func IsAllowedOrigin(origin string) bool {
	if strings.HasPrefix(origin, "http") {
		origin = strings.Split(origin, "//")[1]
	}

	for _, allowedOrigin := range AllowedOrigins {
		if allowedOrigin == origin {
			return true
		}
	}
	return false
}

func shorten(ss []string) string {
	if len(ss) == 0 {
		return ""
	}
	s := ss[0]
	if len(s) > 5 {
		return s[:5] + "..."
	}
	return s
}
