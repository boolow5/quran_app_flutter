package models

import (
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

const (
	JWT_AUDIENCE_NAME       = "meezansync-95a7c"
	JWT_ISSUER_NAME         = "https://securetoken.google.com/meezansync-95a7c"
	JWT_TYPE_AUTHENTICATION = "authentication"
	JWT_TYPE_REFRESH_TOKEN  = "refresh_token"
)

type User struct {
	ID        uint64    `json:"id" db:"id"`
	UID       string    `json:"uid" db:"uid"`
	Email     string    `json:"email" db:"email"`
	Name      string    `json:"name" db:"name"`
	Timezone  string    `json:"timezone" db:"timezone"`
	Streaks   *int      `json:"streaks" db:"streaks"`
	LastPage  *int      `json:"last_page" db:"last_page"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

type NotificationUser struct {
	ID       uint64 `db:"id"`
	Name     string `db:"name"`
	Timezone string `db:"timezone"`
	Tokens   string `db:"tokens"`
}

func (u *NotificationUser) GetTokens() []string {
	return strings.Split(u.Tokens, ",")
}

func GenerateJWTToken(secret, jwtType string, id, companyID, roleID uint64, expireIn time.Duration) (string, error) {
	now := time.Now()
	claims := jwt.MapClaims{
		"sub":  id,
		"type": jwtType,
		"aud":  JWT_AUDIENCE_NAME,
		"exp":  now.Add(expireIn).Unix(),
		"nbf":  now.Unix(),
		"iat":  now.Unix(),
		"iss":  JWT_ISSUER_NAME,
		"cid":  companyID,
		"rid":  roleID,
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS512, claims)
	str, err := token.SignedString([]byte(secret))
	if err != nil {
		return "", err
	}

	return str, nil
}

func VerifyJWTToken(secret, token string) (jwt.MapClaims, error) {
	claims := jwt.MapClaims{}
	_, err := jwt.ParseWithClaims(token, claims, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, jwt.ErrSignatureInvalid
		}
		return []byte(secret), nil
	})
	if err != nil {
		return nil, err
	}
	// check issuer and audience
	if claims["iss"] != JWT_ISSUER_NAME || claims["aud"] != JWT_AUDIENCE_NAME {
		return nil, jwt.ErrSignatureInvalid
	}

	return claims, nil
}
