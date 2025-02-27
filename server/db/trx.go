package db

import (
	"context"
	"database/sql"
)

type txKey struct{}

func WithTx(ctx context.Context, tx *sql.Tx) context.Context {
	return context.WithValue(ctx, txKey{}, tx)
}

func GetTx(ctx context.Context) (*sql.Tx, bool) {
	tx, ok := ctx.Value(txKey{}).(*sql.Tx)
	return tx, ok
}

type TxDatabase struct {
	db Database
}

func NewTxDatabase(db Database) *TxDatabase {
	return &TxDatabase{db: db}
}

// Get checks for transaction in context
func (t *TxDatabase) Get(ctx context.Context, dest interface{}, query string, args ...interface{}) error {
	if tx, ok := GetTx(ctx); ok {
		// If there's a transaction in context, use ExecTx
		_, err := t.db.ExecTx(ctx, tx, query, args...)
		return err
	}
	return t.db.Get(ctx, dest, query, args...)
}

// Exec checks for transaction in context
func (t *TxDatabase) Exec(ctx context.Context, query string, args ...interface{}) (int64, error) {
	if tx, ok := GetTx(ctx); ok {
		return t.db.ExecTx(ctx, tx, query, args...)
	}
	return t.db.Exec(ctx, query, args...)
}

// ExecTx remains unchanged as it explicitly handles transactions
func (t *TxDatabase) ExecTx(ctx context.Context, tx *sql.Tx, query string, args ...interface{}) (int64, error) {
	return t.db.ExecTx(ctx, tx, query, args...)
}

// Select checks for transaction in context
func (t *TxDatabase) Select(ctx context.Context, dest interface{}, query string, args ...interface{}) error {
	if tx, ok := GetTx(ctx); ok {
		// If there's a transaction in context, use ExecTx
		_, err := t.db.ExecTx(ctx, tx, query, args...)
		return err
	}
	return t.db.Select(ctx, dest, query, args...)
}

// Insert checks for transaction in context
func (t *TxDatabase) Insert(ctx context.Context, query string, args ...interface{}) (int64, error) {
	if tx, ok := GetTx(ctx); ok {
		return t.db.ExecTx(ctx, tx, query, args...)
	}
	return t.db.Insert(ctx, query, args...)
}

func (t *TxDatabase) Begin(ctx context.Context) (*sql.Tx, error) {
	return t.db.Begin(ctx)
}
