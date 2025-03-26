package models

import (
	"context"
	"strconv"
	"time"

	"github.com/boolow5/quran-app-api/db"
)

type Bookmark struct {
	ID         uint64     `json:"id" db:"id"`
	UserID     string     `json:"user_id" db:"user_id"`
	PageNumber int        `json:"pageNumber" db:"page_number"`
	SuraName   string     `json:"suraName" db:"sura_name"`
	CreatedAt  time.Time  `json:"created_at" db:"created_at"`
}

func (b *Bookmark) GetKey() string {
	return "bookmarks:" + b.UserID + ":" + strconv.Itoa(b.PageNumber)
}

func (b *Bookmark) Save(ctx context.Context, db db.Database) error {
	query := `
	INSERT INTO bookmarks
		(user_id, page_number, sura_name, created_at)
	VALUES
		(?, ?, ?, ?)
	ON DUPLICATE KEY UPDATE
		created_at = ?
	`

	id, err := db.Insert(ctx, query, b.UserID, b.PageNumber, b.SuraName, b.CreatedAt)
	if err != nil {
		return err
	}
	b.ID = uint64(id)
	return nil
}

// func (b *Bookmark) ToJSONStrign() string {
// 	data, err := json.Marshal(b)
// 	if err != nil {
// 		return ""
// 	}
// 	return string(data)
// }
//
// func (b *Bookmark) FromJSONString(jsonString string) error {
// 	err := json.Unmarshal([]byte(jsonString), b)
// 	if err != nil {
// 		return err
// 	}
// 	return nil
// }

func SaveBookmarksForUser(ctx context.Context, db db.Database, userID string, bookmarks []Bookmark) error {
	for _, bookmark := range bookmarks {
		bookmark.UserID = userID
		err := bookmark.Save(ctx, db)
		if err != nil {
			return err
		}
	}
	return nil
}

func GetBookmarksForUser(ctx context.Context, db db.Database, userID string) ([]Bookmark, error) {
	var bookmarks []Bookmark
	query := `
	SELECT
		id,
		user_id,
		page_number,
		sura_name,
		created_at
	FROM bookmarks
	WHERE user_id = ?
	`
	err := db.Select(ctx, &bookmarks, query, userID)
	if err != nil {
		return nil, err
	}
	
	return bookmarks, nil
}

func RemoveBookmarkForUser(ctx context.Context, db db.Database, userID string, pageNumber string) error {
	query := `
	DELETE FROM bookmarks
	WHERE user_id = ? AND page_number = ?
	`
	_, err := db.Exec(ctx, query, userID, pageNumber)
	if err != nil {
		return err
	}
	return nil
}

