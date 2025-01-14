package middlewares

import (
	"context"
	"fmt"
	"net/http"
	"strings"

	firebase "firebase.google.com/go/v4"
	"github.com/gin-gonic/gin"
	"google.golang.org/api/option"
)

type FirebaseAuth struct {
	app *firebase.App
}

// User represents the Firebase user information we'll attach to the request context
type User struct {
	UID   string
	Email string
}

// NewFirebaseAuth initializes Firebase Auth
func NewFirebaseAuth(credentialsFile string) (*FirebaseAuth, error) {
	opt := option.WithCredentialsFile(credentialsFile)
	app, err := firebase.NewApp(context.Background(), nil, opt)
	if err != nil {
		return nil, fmt.Errorf("error initializing firebase: %v", err)
	}

	return &FirebaseAuth{app: app}, nil
}

// Middleware verifies the Firebase JWT token for Gin
func (fa *FirebaseAuth) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		fmt.Printf("[middleware] Verifying Firebase JWT token\n")

		// Get token from Authorization header
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			fmt.Printf("[middleware] No authorization header\n")
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error": "No authorization header",
			})
			return
		}

		// Remove 'Bearer ' prefix
		idToken := strings.Replace(authHeader, "Bearer ", "", 1)

		if idToken == "" {
			fmt.Printf("[middleware] No token found in Authorization header\n")
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error": "No token found in Authorization header",
			})
			return
		}

		// Initialize Firebase Auth client
		client, err := fa.app.Auth(c.Request.Context())
		if err != nil {
			fmt.Printf("[middleware] Error initializing auth client: %v\n", err)
			c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
				"error": "Error initializing auth client",
			})
			return
		}

		// Verify the token
		token, err := client.VerifyIDToken(c.Request.Context(), idToken)
		if err != nil {
			fmt.Printf("[middleware] Error verifying token: %v\n", err)
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error": "Invalid token",
			})
			return
		}

		id, ok := token.Claims["user_id"].(string)
		if !ok {
			fmt.Printf("[middleware] Invalid user ID: %T\n", token.Claims["user_id"])
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error": "Invalid token",
			})
			return
		}

		email, ok := token.Claims["email"].(string)
		if !ok {
			fmt.Printf("[middleware] Invalid email: %T\n", token.Claims["email"])
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error": "Invalid token",
			})
			return
		}

		fmt.Printf("[middleware] User ID: %s, Email: %s\n", id, email)
		fmt.Printf("[middleware] User ID: %s\n", token.UID)

		// Create user object from token claims
		user := &User{
			UID:   token.UID,
			Email: email,
		}

		// Set user in Gin context
		c.Set("user_id", id)
		c.Set("user", user)
		c.Next()
	}
}

// GetUser helper function to get user from Gin context
func GetUser(c *gin.Context) (*User, bool) {
	user, exists := c.Get("user")
	if !exists {
		return nil, false
	}
	u, ok := user.(*User)
	return u, ok
}
