package db

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"

	"github.com/boolow5/quran-app-api/logger"
	_ "github.com/go-sql-driver/mysql"
	"github.com/jmoiron/sqlx"
)

var (
	log = logger.WithFields(logger.Fields{
		"package": "commons",
	})
)

type Database interface {
	Get(ctx context.Context, dest interface{}, query string, args ...interface{}) error
	Exec(ctx context.Context, query string, args ...interface{}) (RowsAffected int64, err error)
	ExecTx(ctx context.Context, tx *sql.Tx, query string, args ...interface{}) (RowsAffected int64, err error)
	Select(ctx context.Context, dest interface{}, query string, args ...interface{}) error
	Insert(ctx context.Context, query string, args ...interface{}) (insertedID int64, err error)
	Begin(ctx context.Context) (*sql.Tx, error)
}

type MySQLDB struct {
	db *sqlx.DB
}

// Exec implements Database.
func (m MySQLDB) Exec(ctx context.Context, query string, args ...interface{}) (RowsAffected int64, err error) {
	result, err := m.db.Exec(query, args...)
	if err != nil {
		return 0, err
	}

	rowsAffected, err := result.RowsAffected()

	return rowsAffected, err
}

// ExecTx implements Database.
func (m MySQLDB) ExecTx(ctx context.Context, tx *sql.Tx, query string, args ...interface{}) (RowsAffected int64, err error) {
	result, err := tx.Exec(query, args...)
	if err != nil {
		return 0, err
	}

	rowsAffected, err := result.RowsAffected()

	return rowsAffected, err
}

// Get implements Database.
func (m MySQLDB) Get(ctx context.Context, dest interface{}, query string, args ...interface{}) error {
	return m.db.Get(dest, query, args...)
}

// Select implements Database.
func (m MySQLDB) Select(ctx context.Context, dest interface{}, query string, args ...interface{}) error {
	return m.db.Select(dest, query, args...)
}

// Insert implements Database.
func (m MySQLDB) Insert(ctx context.Context, query string, args ...interface{}) (insertedID int64, err error) {
	result, err := m.db.Exec(query, args...)
	if err != nil {
		return 0, err
	}

	return result.LastInsertId()
}

// Begin implements Database.
func (m MySQLDB) Begin(ctx context.Context) (*sql.Tx, error) {
	return m.db.Begin()
}

func NewMysqlDB(dsn string) (*MySQLDB, error) {
	if strings.TrimSpace(dsn) == "" {
		fmt.Printf("NewMysqlDB: dsn is empty")
		return nil, errors.New("MySQL dsn is empty")
	}
	// log.Infof("NewMysqlDB dsn 0: %s", dsn)
	if strings.Contains(dsn, "parseTime=false") {
		dsn = strings.Replace(dsn, "parseTime=false", "parseTime=true", 1)
	} else if !strings.Contains(dsn, "parseTime=true") {
		dsn = dsn + "?parseTime=true"
	}

	db, err := sqlx.Connect("mysql", dsn)
	if err != nil {
		// log.Infof("NewMysqlDB dsn 1: %s", dsn)
		fmt.Printf("NewMysqlDB failed to connect: %v", err)
		return nil, err
	}

	// test database connection
	err = db.Ping()
	if err != nil {
		// log.Infof("NewMysqlDB dsn 2: %s", dsn)
		fmt.Printf("NewMysqlDB failed to ping: %v", err)
		return nil, err
	}

	return &MySQLDB{db: db}, nil
}
