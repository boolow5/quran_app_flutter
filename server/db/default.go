package db

import (
	"context"
	"fmt"
	"os"
	"strings"
)

// InitTables reads the content of create_tables.sql and executes it
func InitTables(db Database) {
	// read file as string
	filePath := os.Getenv("QURAN_API_MYSQL_CREATE_TABLES_PATH")
	if strings.TrimSpace(filePath) == "" {
		filePath = "./db/create_tables.sql"
	}

	// read file
	fileContent, err := os.ReadFile(filePath)
	if err != nil {
		if err.Error() == "no such file or directory" {
			filePath = "./create_tables.sql"
			fileContent, err = os.ReadFile(filePath)
		}
		if err != nil {
			panic(fmt.Sprintf("[DB] Failed to read create_tables.sql file: %v", err))
		}
	}

	// trim
	fileContent = []byte(strings.TrimSpace(string(fileContent)))

	statements := []string{}

	// split
	statements = strings.Split(string(fileContent), "----------------------------------")

	for _, statement := range statements {
		statement = strings.TrimSpace(statement)
		if statement == "" || strings.HasPrefix(statement, "--") {
			continue
		}

		tableName := getTableName(statement)
		_, err = db.Exec(context.Background(), statement)
		if err != nil {
			if (strings.Contains(err.Error(), "already exists") || strings.Contains(err.Error(), "Duplicate table")) {
				fmt.Printf("[DB] Table %s already exists\n", tableName)
				continue
			}
			panic(fmt.Sprintf("[DB] Failed to create table: %s, ERROR: %v", tableName, err))
		}

		fmt.Printf("[DB] Table %s created\n", tableName)
	}

	if len(statements) == 0 {
		fmt.Println("[WARN] No statements found in create_tables.sql")
		return
	}
	fmt.Println("[DB] InitTables success")
}

func getTableName(statement string) string {
	if strings.Contains(strings.ToUpper(statement), "EXISTS") {
		statement = strings.Split(statement, "EXISTS ")[1]
		statement = strings.Split(statement, "(")[0]
	} else {
		statement = strings.Split(statement, "CREATE TABLE")[1]
		statement = strings.Split(statement, "(")[0]
	}

	return strings.TrimSpace(statement)
}
