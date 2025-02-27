package db

import (
	"context"
	"database/sql"
	"fmt"
	"strings"

	"github.com/boolow5/quran-app-api/utils"
)

const (
	DefaultPage = uint64(1)
	DefaultSize = uint64(10)
)

type Filters map[string]interface{}

type Pagination struct {
	Page        uint64
	PageSize    uint64
	PageCount   uint64
	ResultCount uint64
	Results     []*any
}

func NewPagination(page, pageSize *uint64) Pagination {
	if page == nil {
		page = utils.ToPtr(DefaultPage)
	}

	if pageSize == nil {
		pageSize = utils.ToPtr(DefaultSize)
	}

	return Pagination{
		Page:        *page,
		PageSize:    *pageSize,
		PageCount:   0,
		ResultCount: 0,
		Results:     []*any{},
	}
}

func (p Pagination) Limit() uint64 {
	return p.PageSize
}

func (p Pagination) Offset() uint64 {
	return (p.Page - 1) * p.PageSize
}

type Store interface {
	Create(ctx context.Context, model Model) error
	FindByField(ctx context.Context, out Model, fieldName, value string) error
	Update(ctx context.Context, model Model) error
	FindById(ctx context.Context, out Model, id uint64) error
	Delete(ctx context.Context, tableName string, id uint64) error
	FindAll(ctx context.Context, out interface{}, model Model, filters Filters, pagination Pagination) error
	Count(ctx context.Context, tableName string, filters Filters) (int64, error)
	FindByIds(ctx context.Context, out interface{}, model Model, ids []uint64) error
	Execute(ctx context.Context, query string, args ...interface{}) error
	Select(ctx context.Context, dest interface{}, query string, args ...interface{}) error
	Begin(ctx context.Context) (*sql.Tx, error)
}

type DatabaseStore interface {
	Store
}

type databaseStore struct {
	db Database
}

func NewDatabaseStore(db Database) DatabaseStore {
	return &databaseStore{db: db}
}

// Begin implements AuthenticationStore.
func (s *databaseStore) Begin(ctx context.Context) (*sql.Tx, error) {
	return s.db.Begin(ctx)
}

// Count implements DatabaseStore.
func (n *databaseStore) Count(ctx context.Context, tableName string, filters Filters) (count int64, err error) {
	err = n.db.Get(ctx, &count, "SELECT COUNT(*) FROM "+tableName)

	return count, err
}

// Create implements DatabaseStore.
func (n *databaseStore) Create(ctx context.Context, model Model) error {
	cols := utils.GetColumnsWithValues(model)
	if len(cols) <= 0 {
		return utils.ErrNoFieldsToUpdate
	}

	query := "INSERT INTO " + model.TableName()

	colNames := []string{}
	values := []interface{}{}
	for key, val := range cols {
		colNames = append(colNames, key)
		values = append(values, val)
	}

	query += "(" + strings.Join(colNames, ", ") + ")"
	query += " VALUES " + utils.Placeholders(len(values))

	log.Infof("query: %s\n", query)

	id, err := n.db.Insert(ctx, query, values...)
	if err == nil && id > 0 {
		model.SetID(uint64(id))
	} else if id <= 0 {
		log.Errorf("Failed to create item: %v\n", err)
	}

	if err != nil {
		log.Errorf("Failed to create item: %v\n", err)
		return err
	}

	return err
}

// Delete implements DatabaseStore.
func (n *databaseStore) Delete(ctx context.Context, tableName string, id uint64) error {
	rowAffected, err := n.db.Exec(ctx, "DELETE FROM "+tableName+" WHERE id = ?", id)

	if rowAffected != 1 {
		return err
	}

	return nil
}

// FindAll implements DatabaseStore.
func (n *databaseStore) FindAll(ctx context.Context, out interface{}, model Model, filterMap Filters, pagination Pagination) (err error) {
	filters := []string{}
	for key, value := range filterMap {
		if value == "" {
			delete(filterMap, key)
		} else {
			filters = append(filters, key+" = ? ", fmt.Sprintf("%v", value))
		}
	}

	query := "SELECT * FROM " + model.TableName() + `
	WHERE ` + strings.Join(filters, " AND ")

	err = n.db.Select(ctx, out, query)

	return err
}

// FindByField implements DatabaseStore.
func (n *databaseStore) FindByField(ctx context.Context, out Model, fieldName string, value string) (err error) {
	err = n.db.Get(ctx, out, "SELECT * FROM "+out.TableName()+" WHERE "+fieldName+" = ?", value)
	if err != nil {
		return err
	}

	return nil
}

// FindById implements DatabaseStore.
func (n *databaseStore) FindById(ctx context.Context, out Model, id uint64) (err error) {
	err = n.db.Get(ctx, out, "SELECT * FROM "+out.TableName()+" WHERE id = ?", id)
	if err != nil {
		log.Errorf("Failed to get item: %v\n", err)
		return err
	}

	return nil
}

// FindByIds implements DatabaseStore.
func (n *databaseStore) FindByIds(ctx context.Context, out interface{}, model Model, ids []uint64) (err error) {
	err = n.db.Select(ctx, out, "SELECT * FROM "+model.TableName()+" WHERE id IN (?)", ids)
	if err != nil {
		log.Errorf("Failed to get items: %v\n", err)
		return err
	}

	return nil
}

// Update implements DatabaseStore.
func (n *databaseStore) Update(ctx context.Context, model Model) error {
	cols := utils.GetColumnsWithValues(model)
	if len(cols) <= 0 {
		return utils.ErrNoFieldsToUpdate
	}

	query := "UPDATE " + model.TableName()

	values := []interface{}{}

	keyVals := []string{}
	for key, val := range cols {
		keyVals = append(keyVals, fmt.Sprintf("%s = ?", key))
		values = append(values, val)
	}

	query += " SET " + strings.Join(keyVals, ", ")

	query += " WHERE id = ?"

	values = append(values, fmt.Sprintf("%v", model.GetID()))
	rowsAffected, err := n.db.Exec(ctx, query, values...)

	if rowsAffected != 1 {
		return err
	}

	return nil
}

func (n *databaseStore) Execute(ctx context.Context, query string, args ...interface{}) error {
	affectedRows, err := n.db.Exec(ctx, query, args...)

	if err != nil {
		return err
	}

	if affectedRows == 0 {
		return utils.ErrNoRowsAffected
	}

	return nil
}

func (n *databaseStore) Select(ctx context.Context, dest interface{}, query string, args ...interface{}) error {
	return n.db.Select(ctx, dest, query, args...)
}
