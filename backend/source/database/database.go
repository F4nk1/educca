package database

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	_ "github.com/jackc/pgx/v5/stdlib"

	"github.com/F4nk1/educca/backend/source/config"
	"github.com/F4nk1/educca/backend/source/tracer"
)

type Database struct {
	Db *sql.DB
}

func NewDataBase(ctx context.Context, config *config.Config) (*Database, error) {
	tracer.Debug(ctx, "Initializing database connection")

	connectionString := config.GetStringDBConnection()

	db, err := sql.Open(config.Database.Driver, connectionString)
	if err != nil {
		tracer.Errorf(ctx, "Failed to open database connection: %s", err)
		return nil, err
	}

	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(10)
	db.SetConnMaxLifetime(5 * time.Minute)

	if err := db.PingContext(ctx); err != nil {
		tracer.Errorf(ctx, "Failed to ping database: %s", err)
		return nil, fmt.Errorf("cannot connect to database: %v", err)
	}

	tracer.Debug(ctx, "Connected to database successfully")

	return &Database{
		Db: db,
	}, nil
}

func (c *Database) Ping(ctx context.Context) error {
	if c == nil || c.Db == nil {
		return fmt.Errorf("database connection is not initialized")
	}
	return c.Db.PingContext(ctx)
}

func (c *Database) Close() error {
	return c.Db.Close()
}
