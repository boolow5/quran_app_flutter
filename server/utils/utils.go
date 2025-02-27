package utils

import (
	"errors"
	"fmt"
	"reflect"
	"strings"
)

var (
	ErrUserAlreadyExists    = errors.New("user already exists")
	ErrWrongEmailOrPassword = errors.New("wrong email or password")
	ErrAuthenticationFailed = errors.New("authentication failed")
	ErrUserNotFound         = errors.New("user not found")
	ErrInvalidToken         = errors.New("invalid token")
	ErrTokenExpired         = errors.New("token expired")
	ErrInvalidRole          = errors.New("invalid role")
	ErrInvalidRequest       = errors.New("invalid request")
	ErrInvalidCompany       = errors.New("invalid company")
	ErrInvalidProduct       = errors.New("invalid product")
	ErrInvalidTransaction   = errors.New("invalid transaction")
	ErrFailedToGenerateJWT  = errors.New("failed to generate jwt")
	ErrResetCodeAlreadyUsed = errors.New("reset code already used")
	ErrResetCodeTypeInvalid = errors.New("invalid reset code type")
	ErrNoFieldsToUpdate     = errors.New("no fields to update")
	ErrPasswordMaxExceeded  = errors.New("password cannot be longer than 32 characters")
	ErrNoRowsAffected       = errors.New("no rows affected")
)

func ToPtr[T any](value T) *T {
	return &value
}

// GetColumnsWithValues takes any struct and returns a map of column names (from db tags)
// to their values, excluding fields with nil values. It also handles embedded structs.
func GetColumnsWithValues(v interface{}) map[string]interface{} {
	result := make(map[string]interface{})

	// Get the reflected value and type
	val := reflect.ValueOf(v)
	typ := val.Type()

	// If it's a pointer, get the underlying element
	if val.Kind() == reflect.Ptr {
		val = val.Elem()
		typ = typ.Elem()
	}

	// Only process if it's a struct
	if val.Kind() != reflect.Struct {
		return result
	}

	// Process the struct fields
	processStructFields(val, typ, result)

	return result
}

// processStructFields handles the recursive processing of struct fields
func processStructFields(val reflect.Value, typ reflect.Type, result map[string]interface{}) {
	for i := 0; i < val.NumField(); i++ {
		field := val.Field(i)
		fieldType := typ.Field(i)

		// Handle embedded structs
		if fieldType.Anonymous {
			// Get the embedded struct's value and type
			embedVal := field
			embedType := fieldType.Type

			// If it's a pointer, get the element it points to
			if embedVal.Kind() == reflect.Ptr {
				if embedVal.IsNil() {
					continue
				}
				embedVal = embedVal.Elem()
				embedType = embedType.Elem()
			}

			// If it's a struct, process its fields recursively
			if embedVal.Kind() == reflect.Struct {
				processStructFields(embedVal, embedType, result)
			}
			continue
		}

		// Get the db tag
		dbTag := fieldType.Tag.Get("db")
		jsonTag := fieldType.Tag.Get("json")
		if dbTag == "" && jsonTag == "" {
			continue
		}

		if dbTag == "" {
			dbTag = jsonTag
		}

		// Handle pointer fields
		if field.Kind() == reflect.Ptr {
			// Skip if the pointer is nil
			if field.IsNil() {
				continue
			}
			// Get the value the pointer points to
			result[dbTag] = field.Elem().Interface()
			continue
		}

		// For non-pointer fields, add if they don't have their zero value
		if !field.IsZero() {
			result[dbTag] = field.Interface()
		}
	}
}

func CreateTypeInstance(slice interface{}) (interface{}, error) {
	fmt.Printf("[CreateTypeInstance] slice: %T\n", slice)
	// Get the type of the slice
	sliceType := reflect.TypeOf(slice)
	if sliceType.Kind() != reflect.Slice {
		fmt.Errorf("[CreateTypeInstance] input must be a slice, got %v\n", sliceType.Kind())
		return nil, fmt.Errorf("input must be a slice, got %v", sliceType.Kind())
	}

	// Get the element type of the slice
	elemType := sliceType.Elem()

	// If it's a pointer type, get the element type it points to
	if elemType.Kind() == reflect.Ptr {
		elemType = elemType.Elem()
		fmt.Printf("[CreateTypeInstance] ptr elemType: %v\n", elemType)
	} else {
		fmt.Printf("[CreateTypeInstance] elemType: %v\n", elemType)
	}

	// Create a new instance of the concrete type
	instance := reflect.New(elemType).Interface()
	fmt.Printf("[CreateTypeInstance] instance: %T\n", instance)

	return instance, nil
}

func Placeholders(count int) string {
	placeholders := make([]string, count)
	for i := range placeholders {
		placeholders[i] = "?"
	}
	return fmt.Sprintf("(%s) ", strings.Join(placeholders, ", "))
}
