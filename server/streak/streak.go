package streak

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/boolow5/quran-app-api/db"
)

// Minimum reading time in seconds to count a day (5 minutes = 300 seconds)
const MinReadingTimeThreshold = 300

// Models
type ReadingEvent struct {
	ID          uint64    `json:"id" db:"id"`
	UserID      uint64    `json:"user_id" db:"user_id"`
	PageNumber  int       `json:"page_number" db:"page_number"`
	SurahName   string    `json:"surah_name" db:"surah_name"`
	SecondsOpen int       `json:"seconds_open" db:"seconds_open"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
}

type DailySummary struct {
	ID           uint64    `json:"id" db:"id"`
	UserID       uint64    `json:"user_id" db:"user_id"`
	Date         time.Time `json:"date" db:"date"`
	TotalSeconds int       `json:"total_seconds" db:"total_seconds"`
	ThresholdMet bool      `json:"threshold_met" db:"threshold_met"`
}

type UserStreak struct {
	UserID         uint64       `json:"user_id" db:"user_id"`
	CurrentStreak  int          `json:"current_streak" db:"current_streak"`
	LongestStreak  int          `json:"longest_streak" db:"longest_streak"`
	LastActiveDate sql.NullTime `json:"last_active_date" db:"last_active_date"`
}

type RecentPage struct {
	PageNumber int       `json:"page_number" db:"page_number"`
	SurahName  string    `json:"surah_name" db:"surah_name"`
	StartDate  time.Time `json:"start_date" db:"start_date"`
	EndDate    time.Time `json:"end_date" db:"end_date"`
}

// RecordReadingEvent stores a new reading event
func RecordReadingEvent(ctx context.Context, db db.Database, event ReadingEvent) error {
	query := `
		INSERT INTO reading_events 
		(user_id, page_number, surah_name, seconds_open, created_at) 
		VALUES (?, ?, ?, ?, ?)
	`

	// validation
	if event.SecondsOpen < 30 {
		return fmt.Errorf("seconds_open must be greater than 30")
	}
	if event.SecondsOpen > 600 {
		event.SecondsOpen = 600
	}
	if event.PageNumber < 1 || event.PageNumber > 604 {
		return fmt.Errorf("page_number must be between 1 and 604")
	}

	_, err := db.Insert(ctx, query, event.UserID, event.PageNumber, event.SurahName, event.SecondsOpen, event.CreatedAt)
	if err != nil {
		return fmt.Errorf("failed to record reading event: %w", err)
	}

	return nil
}

// UpdateDailySummary calculates and updates the daily summary for a user
func UpdateDailySummary(ctx context.Context, db db.Database, userID uint64, date time.Time) (totalSeconds int, err error) {
	// Format date as YYYY-MM-DD for SQL
	dateStr := date.Format("2006-01-02")

	fmt.Printf("Updating daily summary for user: %d, date: %s\n", userID, dateStr)

	// Calculate total seconds for the day
	query := `
		SELECT COALESCE(SUM(seconds_open), 0) 
		FROM reading_events 
		WHERE user_id = ? 
		AND DATE(created_at) = ?
	`
	err = db.Get(ctx, &totalSeconds, query, userID, dateStr)
	if err != nil {
		return totalSeconds, fmt.Errorf("failed to calculate daily total: %w", err)
	}

	// Check if threshold is met
	thresholdMet := totalSeconds >= MinReadingTimeThreshold

	fmt.Printf("Total seconds: %d, threshold met: %t\n", totalSeconds, thresholdMet)

	// Upsert daily summary
	upsertQuery := `
		INSERT INTO daily_summaries (user_id, date, total_seconds, threshold_met)
		VALUES (?, ?, ?, ?)
		ON DUPLICATE KEY UPDATE
		total_seconds = VALUES(total_seconds),
		threshold_met = VALUES(threshold_met)
	`
	_, err = db.Exec(ctx, upsertQuery, userID, dateStr, totalSeconds, thresholdMet)
	if err != nil {
		fmt.Printf("Failed to upsert daily summary: %v\n", err)
		return totalSeconds, fmt.Errorf("failed to update daily summary: %w", err)
	}

	fmt.Printf("Updated daily summary for user: %d, date: %s\n", userID, dateStr)
	// Update streak if needed
	err = UpdateStreak(ctx, db, userID, date, thresholdMet)
	return totalSeconds, err
}

// UpdateStreak updates a user's streak based on their activity
func UpdateStreak(ctx context.Context, db db.Database, userID uint64, today time.Time, thresholdMet bool) error {
	tx, err := db.Begin(ctx)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}

	defer func() {
		if err != nil {
			tx.Rollback()
		}
	}()

	// Get current streak info
	var streak UserStreak
	query := `
		SELECT user_id, current_streak, longest_streak, last_active_date
		FROM user_streaks
		WHERE user_id = ?
	`
	err = db.Get(ctx, &streak, query, userID)
	if err != nil && err != sql.ErrNoRows {
		return fmt.Errorf("failed to get streak info: %w", err)
	}

	// Initialize streak if not exists
	if err == sql.ErrNoRows {
		streak = UserStreak{
			UserID:        userID,
			CurrentStreak: 0,
			LongestStreak: 0,
		}
	}

	// Format dates for comparison
	todayDate := today.Format("2006-01-02")
	yesterday := today.AddDate(0, 0, -1)
	yesterdayDate := yesterday.Format("2006-01-02")

	var newStreak int

	if thresholdMet {
		if streak.LastActiveDate.Valid {
			lastActiveDate := streak.LastActiveDate.Time.Format("2006-01-02")
			fmt.Printf("Threshold met for user: %d\tLast active date: %s\n", userID, lastActiveDate)

			// Check if last active date was yesterday
			if lastActiveDate == yesterdayDate {
				// Continue streak
				newStreak = streak.CurrentStreak + 1
				fmt.Printf("Continuing streak for user: %d\tNew streak: %d\n", userID, newStreak)
			} else if lastActiveDate == todayDate {
				// Already processed today, keep current streak
				newStreak = streak.CurrentStreak
				fmt.Printf("Already processed today for user: %d\tNew streak: %d\n", userID, newStreak)
			} else {
				// Streak broken, start new streak
				newStreak = 1
				fmt.Printf("Streak broken for user: %d\tNew streak: %d\n", userID, newStreak)
			}
		} else {
			// First time reading, start streak at 1
			newStreak = 1
			fmt.Printf("First time reading for user: %d\tNew streak: %d\n", userID, newStreak)
		}
	} else {
		// Threshold not met, keep existing streak
		newStreak = streak.CurrentStreak
		fmt.Printf("Threshold not met for user: %d\tNew streak: %d\n", userID, newStreak)
	}

	// Calculate longest streak
	longestStreak := streak.LongestStreak
	if newStreak > longestStreak {
		longestStreak = newStreak
		fmt.Printf("Longest streak updated for user: %d\tNew longest streak: %d\n", userID, longestStreak)
	}

	// Update or insert streak record
	upsertQuery := `
		INSERT INTO user_streaks (user_id, current_streak, longest_streak, last_active_date)
		VALUES (?, ?, ?, ?)
		ON DUPLICATE KEY UPDATE
		current_streak = VALUES(current_streak),
		longest_streak = VALUES(longest_streak),
		last_active_date = VALUES(last_active_date)
	`

	// Only update last_active_date if threshold was met today
	var lastActiveDate interface{} = nil
	if thresholdMet {
		lastActiveDate = todayDate
	} else if streak.LastActiveDate.Valid {
		lastActiveDate = streak.LastActiveDate.Time.Format("2006-01-02")
	}

	_, err = db.ExecTx(ctx, tx, upsertQuery, userID, newStreak, longestStreak, lastActiveDate)
	if err != nil {
		return fmt.Errorf("failed to update streak: %w", err)
	}

	return tx.Commit()
}

// ProcessDailyStreaks is a function that can be run as a daily scheduled job
func ProcessDailyStreaks(ctx context.Context, db db.Database, todayDate time.Time) error {
	// Get all users who had reading activity today
	today := todayDate.Format("2006-01-02")

	var userIDs []uint64
	query := `
		SELECT DISTINCT user_id 
		FROM reading_events 
		WHERE DATE(created_at) = ?
	`

	err := db.Select(ctx, &userIDs, query, today)
	if err != nil {
		return fmt.Errorf("failed to get active users: %w", err)
	}

	// Process each user's streak
	for _, userID := range userIDs {
		_, err := UpdateDailySummary(ctx, db, userID, todayDate)
		if err != nil {
			// Log error but continue with other users
			fmt.Printf("Error updating streak for user %d: %v\n", userID, err)
		}
	}

	return nil
}

// GetUserStreak retrieves the current streak information for a user
func GetUserStreak(ctx context.Context, db db.Database, userID uint64) (UserStreak, error) {
	var streak UserStreak
	query := `
		SELECT user_id, current_streak, longest_streak, last_active_date
		FROM user_streaks
		WHERE user_id = ?
	`

	err := db.Get(ctx, &streak, query, userID)
	if err == sql.ErrNoRows {
		// User has no streak yet, return zero values
		return UserStreak{UserID: userID, CurrentStreak: 0, LongestStreak: 0}, nil
	}
	if err != nil {
		return UserStreak{}, fmt.Errorf("failed to get user streak: %w", err)
	}

	return streak, nil
}

func GetRecentPages(ctx context.Context, db db.Database, userID uint64, limit int) ([]RecentPage, error) {
	var pages []RecentPage

	query := ` 
	WITH RankedPages AS (
		SELECT 
			page_number,
			surah_name,
			created_at as start_date,
			page_number - CAST(ROW_NUMBER() OVER (ORDER BY page_number) AS SIGNED) AS sequence_group
		FROM (
			SELECT DISTINCT
				page_number,
				surah_name,
				created_at
			FROM meezansync_app_db.reading_events
			WHERE user_id = ? AND seconds_open >= 30
		) AS distinct_pages
	), 
	LastPagesInSequence AS (
		SELECT 
			page_number,
			surah_name,
			start_date,
			sequence_group,
			ROW_NUMBER() OVER (PARTITION BY sequence_group ORDER BY start_date DESC) AS seq_rank
		FROM RankedPages
	),
	LatestDistinctPages AS (
		SELECT 
			page_number,
			surah_name,
			start_date,
			ROW_NUMBER() OVER (PARTITION BY page_number ORDER BY start_date DESC) AS page_rank
		FROM LastPagesInSequence
		WHERE seq_rank = 1
	)
	SELECT 
		page_number,
		surah_name,
		start_date
	FROM LatestDistinctPages
	WHERE page_rank = 1
	ORDER BY start_date DESC
	LIMIT ?; 
  `

	err := db.Select(ctx, &pages, query, userID, limit)
	if err != nil {
		return nil, err
	}
	return pages, nil
}
