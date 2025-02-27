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

// RecordReadingEvent stores a new reading event
func RecordReadingEvent(ctx context.Context, db db.Database, event ReadingEvent) error {
	query := `
		INSERT INTO reading_events 
		(user_id, page_number, surah_name, seconds_open, created_at) 
		VALUES (?, ?, ?, ?, ?)
	`
	_, err := db.Insert(ctx, query, event.UserID, event.PageNumber, event.SurahName, event.SecondsOpen, event.CreatedAt)
	if err != nil {
		return fmt.Errorf("failed to record reading event: %w", err)
	}

	return nil
}

// UpdateDailySummary calculates and updates the daily summary for a user
func UpdateDailySummary(ctx context.Context, db db.Database, userID uint64, date time.Time) error {
	// Format date as YYYY-MM-DD for SQL
	dateStr := date.Format("2006-01-02")

	// Calculate total seconds for the day
	var totalSeconds int
	query := `
		SELECT COALESCE(SUM(seconds_open), 0) 
		FROM reading_events 
		WHERE user_id = ? 
		AND DATE(created_at) = ?
	`
	err := db.Get(ctx, &totalSeconds, query, userID, dateStr)
	if err != nil {
		return fmt.Errorf("failed to calculate daily total: %w", err)
	}

	// Check if threshold is met
	thresholdMet := totalSeconds >= MinReadingTimeThreshold

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
		return fmt.Errorf("failed to update daily summary: %w", err)
	}

	// Update streak if needed
	return UpdateStreak(ctx, db, userID, date, thresholdMet)
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

			// Check if last active date was yesterday
			if lastActiveDate == yesterdayDate {
				// Continue streak
				newStreak = streak.CurrentStreak + 1
			} else if lastActiveDate == todayDate {
				// Already processed today, keep current streak
				newStreak = streak.CurrentStreak
			} else {
				// Streak broken, start new streak
				newStreak = 1
			}
		} else {
			// First time reading, start streak at 1
			newStreak = 1
		}
	} else {
		// Threshold not met, keep existing streak
		newStreak = streak.CurrentStreak
	}

	// Calculate longest streak
	longestStreak := streak.LongestStreak
	if newStreak > longestStreak {
		longestStreak = newStreak
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
func ProcessDailyStreaks(ctx context.Context, db db.Database) error {
	// Get all users who had reading activity today
	today := time.Now().Format("2006-01-02")

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
		err := UpdateDailySummary(ctx, db, userID, time.Now())
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
