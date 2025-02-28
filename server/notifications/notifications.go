package notifications

import (
	"context"
	"encoding/base64"
	"fmt"
	"os"
	"strings"
	"time"

	firebase "firebase.google.com/go"
	"firebase.google.com/go/messaging"
	"github.com/boolow5/quran-app-api/db"
	"github.com/boolow5/quran-app-api/models"
	"google.golang.org/api/option"
)

type FCMPriority string

const (
	FCMPriorityHigh   FCMPriority = "high"
	FCMPriorityNormal FCMPriority = "normal"
	FCMPriorityLow    FCMPriority = "low"
)

var (
	FirebaseClient *messaging.Client
)

func InitFirebase() {
	var err error
	FirebaseClient, err = GetFCMClient()
	if err != nil {
		panic(err)
	}

	fmt.Println("Firebase successfully initialized")
}

func GetFCMClient() (client *messaging.Client, err error) {
	credentialsJSON, err := base64.StdEncoding.DecodeString(os.Getenv("FIREBASE_CREDENTIALS"))
	if err != nil {
		return nil, err
	}

	opt := option.WithCredentialsJSON(credentialsJSON)

	app, err := firebase.NewApp(context.Background(), nil, opt)
	if err != nil {
		fmt.Printf("error initializing app: %v", err)
		return nil, fmt.Errorf("error initializing app: %v", err)
	}

	client, err = app.Messaging(context.Background())
	if err != nil {
		fmt.Printf("error getting Messaging client: %v", err)
		return nil, err
	}

	return client, nil
}

func firstName(name string) string {
	parts := strings.Split(name, " ")
	if len(parts) > 0 {
		// return strings.Join(parts[:len(parts)-1], " ")
		return parts[0]
	}
	return name
}

// SendPushNotification sends a notification to a user
func SendPushNotification(tokens []string, topic, title, message, imgUrl string, priority FCMPriority, data map[string]string, analyticsLabel string) error {
	if imgUrl == "" {
		imgUrl = os.Getenv("FCM_ICON")
	}
	// send notification
	notification := messaging.Notification{
		Title:    title,
		Body:     message,
		ImageURL: imgUrl,
	}

	errs := []string{}

	for _, token := range tokens {
		sendResult, err := FirebaseClient.Send(context.Background(), &messaging.Message{
			Notification: &notification,
			Topic:        topic,
			Android: &messaging.AndroidConfig{
				Priority: string(priority),
			},
			FCMOptions: &messaging.FCMOptions{
				AnalyticsLabel: analyticsLabel,
			},
			Data:  data,
			Token: token,
		})
		if err != nil {
			errs = append(errs, err.Error())
			fmt.Printf("Failed to send message: %v\n", err)
		} else {
			fmt.Printf("Successfully sent message: %s\n", sendResult)
		}

	}

	if len(errs) > 0 {
		fmt.Printf("Errors: %v\n", errs)
		return fmt.Errorf(strings.Join(errs, "\n"))
	}

	return nil
}

func SendTimezoneAwareNotifications(ctx context.Context, db db.Database) error {
	// now := time.Now().UTC()

	// TODO: change to 6am
	morningUsers, err := GetUsersForLocalHour(ctx, db, 4)
	if err != nil {
		fmt.Printf("error getting morning users: %w", err)
	} else {
		fmt.Printf("Morning users: %d\n", len(morningUsers))
	}

	eveningUsers, err := GetUsersForLocalHour(ctx, db, 18)
	if err != nil {
		fmt.Printf("error getting evening users: %w", err)
	} else {
		fmt.Printf("Evening users: %d\n", len(eveningUsers))
	}

	lateEviningUsers, err := GetUsersForLocalHour(ctx, db, 19)
	if err != nil {
		fmt.Printf("error getting late evening users: %w", err)
	} else {
		fmt.Printf("Late Evening users: %d\n", len(lateEviningUsers))
	}

	err = sendStreakNotification("", "Good Morning", "%s! Don't forget to read Quran today to maintain your streak!", morningUsers)
	if err != nil {
		fmt.Printf("Failed to send morning notification to users %d: %v\n", len(morningUsers), err)
	}

	err = sendStreakNotification("", "Good Evening", "%s! Don't forget to read Quran today to maintain your streak!", eveningUsers)
	if err != nil {
		fmt.Printf("Failed to send evening notification to user %d: %v\n", len(eveningUsers), err)
	}

	err = sendStreakNotification("", "Good Evening", "%s! Don't forget to read Quran today to maintain your streak!", lateEviningUsers)
	if err != nil {
		fmt.Printf("Failed to send late evening notification to user %d: %v\n", len(lateEviningUsers), err)
	}

	return nil
}

// GetUsersForLocalHour gets users where their local time matches the target hour
func GetUsersForLocalHour(ctx context.Context, db db.Database, targetHour int) ([]models.NotificationUser, error) {
	var users []models.NotificationUser

	// Find all unique timezones in the system to minimize DB queries
	var timezones []string
	err := db.Select(ctx, &timezones, "SELECT DISTINCT timezone FROM users")
	if err != nil {
		return nil, fmt.Errorf("error fetching timezones: %v", err)
	}

	// Get current UTC time
	now := time.Now().UTC()

	// For each timezone, check if the current hour matches the target hour
	var matchingTimezones []string
	for _, tz := range timezones {
		loc, err := time.LoadLocation(tz)
		if err != nil {
			fmt.Printf("Invalid timezone %s: %v\n", tz, err)
			continue
		}

		// Convert UTC time to local time for this timezone
		localTime := now.In(loc)
		fmt.Printf("%s Local time: %s hour: %d\n", tz, localTime.Format("2006-01-02 15:04:05"), localTime.Hour())

		// If current hour in this timezone matches our target, add it to matching timezones
		if localTime.Hour() == targetHour {
			matchingTimezones = append(matchingTimezones, tz)
		}
	}

	// No matching timezones for this hour
	if len(matchingTimezones) == 0 {
		fmt.Printf("No matching timezones for hour %d\n", targetHour)
		fmt.Println("All timezones:", timezones)
		return []models.NotificationUser{}, nil
	}

	fmt.Printf("Found %d matching timezones for hour %d\n", len(matchingTimezones), targetHour)
	fmt.Println(matchingTimezones)

	// Build query with placeholders for timezone list
	placeholders := ""
	args := make([]interface{}, len(matchingTimezones))
	for i, tz := range matchingTimezones {
		if i > 0 {
			placeholders += ","
		}
		placeholders += "?"
		args[i] = tz
	}

	// Query for all users in the matching timezones who have streaks
	query := fmt.Sprintf(`
	SELECT 
      u.id as id,
      u.name as name,
      u.timezone as timezone,
      GROUP_CONCAT(d.device_token SEPARATOR ',') as tokens
  FROM users u
	JOIN user_streaks st ON u.id = st.user_id
	LEFT JOIN user_devices d ON d.user_id = u.id
	WHERE
      u.timezone IN (%s)
	    AND st.current_streak > 0
      AND st.last_active_date != DATE(NOW())
      AND d.device_token IS NOT NULL
  GROUP BY u.id, u.name, u.timezone
	`, placeholders)

	// fmt.Printf("query: %s args: %v\n", query, args)

	err = db.Select(ctx, &users, query, args...)
	if err != nil {
		fmt.Printf("error fetching users for notification: %w", err)
		return nil, fmt.Errorf("error fetching users for notification: %w", err)
	}

	fmt.Printf("Found %d users for notification\n", len(users))

	return users, nil
}

func sendStreakNotification(topic, title, msgFormat string, users []models.NotificationUser) error {
	fmt.Printf("[sendStreakNotification] title: %s users: %d\n", title, len(users))
	for _, user := range users {
		tokens := user.GetTokens()
		fmt.Printf("[sendStreakNotification] tokens: %d\t%+v\n", len(tokens), tokens)
		message := fmt.Sprintf(msgFormat, firstName(user.Name))
		err := SendPushNotification(tokens, topic, title, message, "", FCMPriorityHigh, nil, "")
		if err != nil {
			fmt.Printf("Failed to send push notification to user %s: %v\n", user.Name, err)
		}
	}
	return nil
}
