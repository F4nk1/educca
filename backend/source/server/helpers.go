package server

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"time"

	"github.com/gorilla/mux"

	"github.com/F4nk1/educca/backend/source/common"
	"github.com/F4nk1/educca/backend/source/service"
	"github.com/F4nk1/educca/backend/source/tracer"
)

func decodeJSON(w http.ResponseWriter, r *http.Request, dst any) bool {
	if err := json.NewDecoder(r.Body).Decode(dst); err != nil {
		tracer.Warnf(r.Context(), "Invalid JSON payload: %s", err)
		common.WriteErrorResponse(w, common.INVALID_REQUEST_ERROR)
		return false
	}
	return true
}

func parseID[T ~int16 | ~int64](w http.ResponseWriter, r *http.Request, param string, bitSize int) (T, bool) {
	raw := mux.Vars(r)[param]
	val, err := strconv.ParseInt(raw, 10, bitSize)
	if err != nil || val <= 0 {
		tracer.Warnf(r.Context(), "Invalid path parameter '%s': %s", param, raw)
		common.WriteErrorMessage(w, common.INVALID_REQUEST_ERROR, "Invalid identifier")
		return 0, false
	}
	return T(val), true
}

func parseOptionalAnio(w http.ResponseWriter, r *http.Request) (*int16, bool) {
	raw := r.URL.Query().Get("anio")
	if raw == "" {
		return nil, true
	}
	val, err := strconv.ParseInt(raw, 10, 16)
	if err != nil || val < 2024 {
		common.WriteErrorMessage(w, common.INVALID_REQUEST_ERROR, "Invalid 'anio' query parameter")
		return nil, false
	}
	anio := int16(val)
	return &anio, true
}

func parseDate(raw string) (time.Time, error) {
	if t, err := time.Parse("2006-01-02", raw); err == nil {
		return t, nil
	}
	return time.Parse(time.RFC3339, raw)
}

func parseDateTime(raw string) (time.Time, error) {
	for _, layout := range []string{time.RFC3339, "2006-01-02T15:04:05", "2006-01-02 15:04:05"} {
		if t, err := time.Parse(layout, raw); err == nil {
			return t, nil
		}
	}
	return time.Time{}, errors.New("invalid datetime format, expected RFC3339 or YYYY-MM-DD HH:MM:SS")
}

func writeServiceError(w http.ResponseWriter, r *http.Request, err error, notFoundMsg string) {
	ctx := r.Context()
	switch {
	case errors.Is(err, service.ErrNotFound):
		common.WriteErrorMessage(w, common.NOT_FOUND_ERROR, notFoundMsg)
	case errors.Is(err, service.ErrAlreadyExists):
		common.WriteErrorResponse(w, common.ALREADY_EXISTS_ERROR)
	case errors.Is(err, service.ErrConflict):
		common.WriteErrorMessage(w, common.CONFLICT_ERROR, err.Error())
	case errors.Is(err, service.ErrInvalidInput):
		common.WriteErrorResponse(w, common.INVALID_REQUEST_ERROR)
	case errors.Is(err, service.ErrInvalidCredentials):
		common.WriteErrorResponse(w, common.INVALID_CREDENTIALS_ERROR)
	case errors.Is(err, service.ErrInactiveUser):
		common.WriteErrorMessage(w, common.ACCESS_DENIED_ERROR, "Inactive user account")
	default:
		tracer.Errorf(ctx, "Database/service error: %s", err)
		common.WriteErrorResponse(w, common.DATABASE_ERROR)
	}
}
