package models

import (
	"context"
	"encoding/json"
	"fmt"
	"strconv"
	"time"
)

type Bookmark struct {
	UserID     string     `json:"user_id"`
	PageNumber int        `json:"pageNumber"`
	SuraName   string     `json:"suraName"`
	StartDate  time.Time  `json:"startDate"`
	EndDate    *time.Time `json:"endDate"`
	UpdatedAt  time.Time  `json:"updatedAt"`
}

func (b *Bookmark) GetKey() string {
	return "bookmarks:" + b.UserID + ":" + strconv.Itoa(b.PageNumber)
}

func (b *Bookmark) Save(ctx context.Context) error {
	// check if saved bookmark is newer
	existing, err := RedisDB.Get(ctx, b.GetKey())
	if err == nil {
		existingBookmark := Bookmark{}
		err = existingBookmark.FromJSONString(existing)
		if err == nil && existingBookmark.UpdatedAt.After(b.UpdatedAt) {
			// already saved bookmark is newer, skipping without error
			return nil
		}
	}
	b.UpdatedAt = time.Now()
	return RedisDB.Set(ctx, b.GetKey(), b.ToJSONStrign())
}

func (b *Bookmark) ToJSONStrign() string {
	data, err := json.Marshal(b)
	if err != nil {
		return ""
	}
	return string(data)
}

func (b *Bookmark) FromJSONString(jsonString string) error {
	err := json.Unmarshal([]byte(jsonString), b)
	if err != nil {
		return err
	}
	return nil
}

func SaveBookmarksForUser(ctx context.Context, userID string, bookmarks []Bookmark) error {
	for _, bookmark := range bookmarks {
		bookmark.UserID = userID
		err := bookmark.Save(ctx)
		if err != nil {
			return err
		}
	}
	return nil
}

func GetBookmarksForUser(ctx context.Context, userID string) ([]Bookmark, error) {
	var bookmarks []Bookmark
	keys, err := RedisDB.GetKeys(ctx, "bookmarks:"+userID+":*")
	if err != nil {
		fmt.Printf("[models.GetBookmarksForUser] Error getting keys: %v\n", err)
		return nil, err
	}

	for _, key := range keys {
		var bookmark Bookmark
		jsonStr, err := RedisDB.Get(ctx, key)
		if err != nil {
			fmt.Printf("[models.GetBookmarksForUser] Error getting bookmark: %v\n", err)
			continue
		}
		err = bookmark.FromJSONString(jsonStr)
		if err != nil {
			fmt.Printf("[models.GetBookmarksForUser] Error parsing bookmark: %v\n", err)
			continue
		}
		bookmarks = append(bookmarks, bookmark)
	}
	return bookmarks, nil
}

func RemoveBookmarkForUser(ctx context.Context, userID string, pageNumber string) error {
	return RedisDB.Del(ctx, "bookmarks:"+userID+":"+pageNumber)
}
