package score

import (
	"context"

	"github.com/boolow5/quran-app-api/db"
)

type DailyScore struct {
	ID               int64  `json:"id" db:"id"`
	Position         int    `json:"position" db:"position"`
	UserID           int64  `json:"user_id" db:"user_id"`
	Date             string `json:"date" db:"date"`
	ReadingTimeScore int    `json:"reading_time_score" db:"reading_time_score"`
	ConsistencyScore int    `json:"consistency_score" db:"consistency_score"`
	ProgressScore    int    `json:"progress_score" db:"progress_score"`
	EngagementScore  int    `json:"engagement_score" db:"engagement_score"`
	TotalScore       int    `json:"total_score" db:"total_score"`
	PagesRead        int    `json:"pages_read" db:"pages_read"`
	ReadingMinutes   int    `json:"reading_minutes" db:"reading_minutes"`
}

type WeeklyScore struct {
	ID              int64 `json:"id" db:"id"`
	UserID          int64 `json:"user_id" db:"user_id"`
	Year            int   `json:"year" db:"year"`
	Week            int   `json:"week" db:"week"`
	TotalScore      int   `json:"total_score" db:"total_score"`
	DaysActive      int   `json:"days_active" db:"days_active"`
	TotalReadingMin int   `json:"total_reading_min" db:"total_reading_min"`
	TotalPagesRead  int   `json:"total_pages_read" db:"total_pages_read"`
}

type UserReadingProgress struct {
	UserID        int64  `json:"user_id" db:"user_id"`
	PageNumber    int    `json:"page_number" db:"page_number"`
	SurahName     string `json:"surah_name" db:"surah_name"`
	FirstReadDate string `json:"first_read_date" db:"first_read_date"`
	ReadCount     int    `json:"read_count" db:"read_count"`
}

// CalculateReadingScore calculates the reading score for a user
// it gets the number of pages read, progress score, and reading minutes
// using that data it calculates other scores
func CalculateReadingScore(ctx context.Context, db db.Database, date string) ([]DailyScore, error) {
	query := `
		SELECT
			re.user_id,
			COUNT(DISTINCT re.page_number) AS pages_read,
			COUNT(DISTINCT re.page_number) * 10 AS progress_score,
			SUM(re.seconds_open) / 60 AS reading_minutes,
			SUM(re.seconds_open) / 60 * 10 AS reading_time_score,
			us.current_streak * 10 AS consistency_score
		FROM reading_events as re
		LEFT JOIN user_streaks as us
			ON re.user_id = us.user_id
		WHERE DATE(created_at) = ?
		GROUP BY re.user_id;
	`
	var scores []DailyScore
	err := db.Select(ctx, &scores, query, date)
	if err != nil {
		return nil, err
	}

	for i := range scores {
		scores[i].Date = date

		if scores[i].ConsistencyScore < 0 {
			scores[i].ConsistencyScore = 0
		}

		if scores[i].ProgressScore < 0 {
			scores[i].ProgressScore = 0
		}

		if scores[i].ConsistencyScore < 50 && scores[i].ReadingMinutes > 30 {
			scores[i].ConsistencyScore = 50
		}

		scores[i].TotalScore = max(
			scores[i].ReadingTimeScore+scores[i].ConsistencyScore+scores[i].ProgressScore+scores[i].EngagementScore,
			0,
		)
	}

	return scores, nil
}

func Leaderboard(ctx context.Context, db db.Database, date string, userID uint64) ([]DailyScore, error) {
	query := `
	SELECT
		u.id AS user_id,
		COALESCE(COUNT(DISTINCT re.page_number), 0) AS pages_read,
		COALESCE(COUNT(DISTINCT re.page_number) * 10, 0) AS progress_score,
		COALESCE(SUM(re.seconds_open) / 60, 0) AS reading_minutes,
		COALESCE(SUM(re.seconds_open) / 60 * 10, 0) AS reading_time_score,
		COALESCE(us.current_streak * 10, 0) AS consistency_score
	FROM (SELECT ? AS id) AS u
	LEFT JOIN reading_events AS re
		ON u.id = re.user_id 
		AND (DATE(re.created_at) = ? OR re.user_id = u.id)
	LEFT JOIN user_streaks AS us
		ON u.id = us.user_id
	GROUP BY u.id;`
	var scores []DailyScore
	err := db.Select(ctx, &scores, query, date, userID)
	if err != nil {
		return nil, err
	}

	// calculate positions
	for i := range scores {
		scores[i].Date = date
		scores[i].TotalScore = max(
			scores[i].ReadingTimeScore+scores[i].ConsistencyScore+scores[i].ProgressScore+scores[i].EngagementScore,
			0,
		)
	}

	return scores, nil
}
