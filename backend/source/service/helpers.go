package service

import (
	"context"
	"database/sql"
	"errors"
	"math"

	"github.com/jackc/pgx/v5/pgconn"
)

const earthRadiusMeters = 6371000.0

var (
	ErrNotFound           = errors.New("resource not found")
	ErrAlreadyExists      = errors.New("resource already exists")
	ErrConflict           = errors.New("operation conflicts with current state or references")
	ErrInvalidInput       = errors.New("invalid input or reference")
	ErrUnprocessable      = errors.New("unprocessable business rule")
	ErrInvalidCredentials = errors.New("invalid credentials")
	ErrInactiveUser       = errors.New("user is inactive")
)

type BusinessError struct {
	Message string
}

func (e *BusinessError) Error() string {
	return e.Message
}

func (e *BusinessError) Is(target error) bool {
	return target == ErrConflict
}

// HaversineMeters calculates the great-circle distance in meters between two geographic coordinates.
func HaversineMeters(lat1, lon1, lat2, lon2 float64) float64 {
	toRad := math.Pi / 180.0
	dLat := (lat2 - lat1) * toRad
	dLon := (lon2 - lon1) * toRad
	rLat1 := lat1 * toRad
	rLat2 := lat2 * toRad

	sinDLat := math.Sin(dLat / 2.0)
	sinDLon := math.Sin(dLon / 2.0)
	a := sinDLat*sinDLat + math.Cos(rLat1)*math.Cos(rLat2)*sinDLon*sinDLon
	if a > 1.0 {
		a = 1.0
	} else if a < 0.0 {
		a = 0.0
	}
	c := 2.0 * math.Atan2(math.Sqrt(a), math.Sqrt(1.0-a))
	return earthRadiusMeters * c
}

func classifyError(err error, isDelete bool) error {
	if err == nil {
		return nil
	}
	if errors.Is(err, sql.ErrNoRows) {
		return ErrNotFound
	}
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) {
		switch pgErr.Code {
		case "23505":
			return ErrAlreadyExists
		case "23503":
			if isDelete {
				return ErrConflict
			}
			return ErrInvalidInput
		case "23514", "22001", "23502", "22P02":
			return ErrInvalidInput
		case "P0001":
			return &BusinessError{Message: pgErr.Message}
		case "P0002":
			return ErrNotFound
		}
	}
	return err
}

func queryRows[T any](ctx context.Context, db *sql.DB, query string, scan func(*sql.Rows) (T, error), args ...any) ([]T, error) {
	rows, err := db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, classifyError(err, false)
	}
	defer rows.Close()

	items := make([]T, 0)
	for rows.Next() {
		item, err := scan(rows)
		if err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}

func (s *service) execBool(ctx context.Context, isDelete bool, query string, args ...any) error {
	var ok bool
	err := s.conn.Db.QueryRowContext(ctx, query, args...).Scan(&ok)
	if err != nil {
		return classifyError(err, isDelete)
	}
	if !ok {
		return ErrNotFound
	}
	return nil
}

func (s *service) scanStringSlice(ctx context.Context, query string, args ...any) ([]string, error) {
	return queryRows(ctx, s.conn.Db, query, func(rows *sql.Rows) (string, error) {
		var v string
		err := rows.Scan(&v)
		return v, err
	}, args...)
}
