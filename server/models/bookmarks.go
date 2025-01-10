package models

import (
	"encoding/json"
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

func (b *Bookmark) Save() error {
	// check if saved bookmark is newer
	existing, err := RedisDB.Get(b.GetKey())
	if err == nil {
		existingBookmark := Bookmark{}
		err = existingBookmark.FromJSONString(existing)
		if err == nil && existingBookmark.UpdatedAt.After(b.UpdatedAt) {
			// already saved bookmark is newer, skipping without error
			return nil
		}
	}
	b.UpdatedAt = time.Now()
	return RedisDB.Set(b.GetKey(), b.ToJSONStrign())
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

func SaveBookmarksForUser(userID string, bookmarks []Bookmark) error {
	for _, bookmark := range bookmarks {
		bookmark.UserID = userID
		err := bookmark.Save()
		if err != nil {
			return err
		}
	}
	return nil
}

func GetBookmarksForUser(userID string) ([]Bookmark, error) {
	var bookmarks []Bookmark
	keys, err := RedisDB.GetKeys("bookmarks:" + userID + ":*")
	if err != nil {
		return nil, err
	}
	for _, key := range keys {
		var bookmark Bookmark
		jsonStr, err := RedisDB.Get(key)
		if err != nil {
			return nil, err
		}
		err = bookmark.FromJSONString(jsonStr)
		if err != nil {
			return nil, err
		}
		bookmarks = append(bookmarks, bookmark)
	}
	return bookmarks, nil
}

func RemoveBookmarkForUser(userID string, pageNumber string) error {
	return RedisDB.Del("bookmarks:" + userID + ":" + pageNumber)
}
