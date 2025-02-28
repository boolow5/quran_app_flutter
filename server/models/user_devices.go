package models

import (
	"context"
	"fmt"

	"github.com/boolow5/quran-app-api/db"
)

// "github.com/boolow5/quran-app-api/db"

type UserDevice struct {
	ID          uint64 `json:"id" db:"id"`
	UID         string `json:"uid" db:"uid"`
	UserID      uint64 `json:"user_id" db:"user_id"`
	DeviceToken string `json:"device_token" db:"device_token"`
}

// GetID implements db.Model.
func (u *UserDevice) GetID() uint64 {
	return u.ID
}

// SetID implements db.Model.
func (u *UserDevice) SetID(id uint64) {
	u.ID = id
}

// TableName implements db.Model.
func (u *UserDevice) TableName() string {
	return "user_devices"
}

// GetID implements db.Model.
func (u *UserDevice) GetUID() string {
	return u.UID
}

// GetDevicesByUserID finds all device tokens for a user
func GetDevicesByUserID(ctx context.Context, db db.Database, userID uint64) ([]UserDevice, error) {
	var devices []UserDevice
	query := "SELECT * FROM user_devices WHERE user_id = ?"
	err := db.Select(ctx, &devices, query, userID)
	if err != nil {
		return nil, err
	}

	return devices, nil
}

// GetDeviceTokensByUserID finds all device tokens for a user
func GetDeviceTokensByUserID(ctx context.Context, db db.Database, userID uint64) (tokens []string, fullName string, err error) {
	fmt.Printf("[GetDeviceTokensByUserID] userID: %d\n", userID)
	query := "SELECT device_token FROM user_devices WHERE user_id = ?"
	err = db.Select(ctx, &tokens, query, userID)
	if err != nil {
		fmt.Printf("[GetDeviceTokensByUserID] error: %v\n", err)
		return nil, "", err
	}

	fmt.Printf("[GetDeviceTokensByUserID] tokens: %v\n", len(tokens))
	if len(tokens) > 0 {
		query = "SELECT name FROM users WHERE id = ?"
		err := db.Select(ctx, &fullName, query, userID)
		if err != nil {
			fmt.Printf("[GetDeviceTokensByUserID] full name error: %v\n", err)
			return nil, "", err
		}
	}

	return tokens, fullName, nil
}

func CreateOrUpdateFCMToken(ctx context.Context, db db.Database, form UserDevice) error {
	if form.DeviceToken == "" {
		return fmt.Errorf("device token is required")
	}

	if form.UserID < 1 {
		return fmt.Errorf("user id is required")
	}

	query := "INSERT INTO user_devices (uid, user_id, device_token) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE device_token = ?"
	_, err := db.Exec(ctx, query, form.UID, form.UserID, form.DeviceToken, form.DeviceToken)
	if err != nil {
		return fmt.Errorf("failed to create or update user device: %w", err)
	}

	return nil
}
