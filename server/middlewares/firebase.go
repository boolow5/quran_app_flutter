package middlewares

import (
	"context"
	"fmt"
	"net/http"
	"strings"
	"time"

	firebase "firebase.google.com/go/v4"
	"github.com/boolow5/quran-app-api/db"
	"github.com/gin-gonic/gin"
	"google.golang.org/api/option"
)

type FirebaseAuth struct {
	app *firebase.App
}

// User represents the Firebase user information we'll attach to the request context
type User struct {
	ID        uint64    `json:"id" db:"id"`
	UID       string    `json:"uid" db:"uid"`
	Email     string    `json:"email" db:"email"`
	Name      string    `json:"name" db:"name"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
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
func (fa *FirebaseAuth) Middleware(db db.Database) gin.HandlerFunc {
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
		user := User{
			UID:   id,
			Email: email,
		}

		fmt.Printf("[middleware] User: %+v\n", user)

		// Sync with local database
		dbID, err := SyncFirebaseUser(c.Request.Context(), db, user)
		if err != nil {
			fmt.Printf("[middleware] Error syncing user: %v\n", err)
			c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
				"error": "Error syncing user",
			})
			return
		}

		// Set user in Gin context
		c.Set("db_user_id", dbID)
		c.Set("user_id", id)
		c.Set("user", &user)
		c.Next()
	}
}

func (fa *FirebaseAuth) Login(db db.Database) gin.HandlerFunc {
	return func(c *gin.Context) {
		form := User{}

		if err := c.ShouldBind(&form); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": err.Error(),
			})
			return
		}

		fmt.Printf("[middleware] Login User: %+v\n", form)

		// get user by uid
		var user User
		query := "SELECT * FROM users WHERE uid = ?"
		err := db.Get(c.Request.Context(), &user, query, form.UID)
		if err != nil {
			fmt.Printf("[middleware] Login Error getting user: %v\n", err)
			fmt.Printf("\tQuery: %v\n", strings.Replace(query, "?", "'"+form.UID+"'", 1))
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": err.Error(),
			})
			return
		}

		if user.ID == 0 {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Invalid or expired token",
			})
			return
		}

		// if found update the name if it's empty
		if user.Name == "" {
			_, err := db.Exec(c.Request.Context(), "UPDATE users SET name = ? WHERE uid = ?", form.Name, form.UID)
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{
					"error": err.Error(),
				})
				return
			}
		}

		c.JSON(http.StatusOK, gin.H{
			"id": user.ID,
		})
	}
}
func SyncFirebaseUser(ctx context.Context, db db.Database, firebaseUser User) (id uint64, err error) {
	var user User = User{UID: firebaseUser.UID, Email: firebaseUser.Email, Name: firebaseUser.Name}
	query := "SELECT * FROM users WHERE uid = ?"
	err = db.Get(ctx, &user, query, firebaseUser.UID)
	if err != nil {
		fmt.Printf("[middleware] Error getting user from database: %v\n", err)
		fmt.Printf("\tQuery: %v\n", strings.Replace(query, "?", "'"+firebaseUser.UID+"'", 1))
	} else {
		fmt.Printf("[middleware] User found in database: %v\n", user)
	}

	if user.ID > 0 { // Found in database
		fmt.Printf("[middleware] User found in database: %v\n", user)
		user.Email = firebaseUser.Email
		user.Name = firebaseUser.Name

		_, err := db.Exec(ctx, "UPDATE users SET email = ?, name = ? WHERE uid = ?", user.Email, user.Name, user.UID)
		return user.ID, err
	}

	fmt.Printf("[middleware] User not found in database: %v\n", user)

	user = firebaseUser
	query = `
    INSERT INTO users (uid, email, name)
    VALUES (?, ?, ?)
  `
	insertedID, err := db.Insert(ctx, query, user.UID, user.Email, user.Name)
	if err == nil {
		user.ID = uint64(insertedID)
	}

	return user.ID, err
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
