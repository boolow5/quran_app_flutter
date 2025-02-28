package main

import (
	"context"
	"fmt"
	"time"

	"github.com/boolow5/quran-app-api/db"
	"github.com/boolow5/quran-app-api/models"
	"github.com/boolow5/quran-app-api/notifications"
	"github.com/boolow5/quran-app-api/streak"
	"github.com/robfig/cron/v3"
)

func StartCronJobs(db db.Database) {
	c := cron.New()

	// Run every hour
	_, err := c.AddFunc("5 * * * *", func() {
		fmt.Printf("Sending timezone aware notifications\n")
		ctx := context.Background()
		err := notifications.SendTimezoneAwareNotifications(ctx, db)
		if err != nil {
			fmt.Printf("Error sending notifications: %v\n", err)
		}
	})

	if err != nil {
		fmt.Printf("Failed to set up cron job: %v", err)
	}

	_, err = c.AddFunc("0 */6 * * *", func() {
		today := time.Now()
		fmt.Printf("Processing daily streaks for %s\n", today.Format("2006-01-02"))

		err = streak.ProcessDailyStreaks(context.Background(), models.MySQLDB, today)
		if err != nil {
			fmt.Printf("Error processing daily streaks: %v\n", err)
		}
	})

	c.Start()
}
