package common

import "net/http"

const (
	// Client errors
	INVALID_REQUEST_ERROR = 1001
	MISSING_FIELDS_ERROR  = 1002
	NOT_FOUND_ERROR       = 1003
	ALREADY_EXISTS_ERROR  = 1004
	CONFLICT_ERROR        = 1005
	UNPROCESSABLE_ERROR   = 1006

	// Auth errors
	INVALID_CREDENTIALS_ERROR = 2001
	ACCESS_DENIED_ERROR       = 2002
	MISSING_PERMISSION_ERROR  = 2003
	ACCOUNT_INACTIVE_ERROR    = 2004

	// Server errors
	DATABASE_ERROR = 5001
	INTERNAL_ERROR = 5002
)

var ErrorCodes = map[int]int{
	INVALID_REQUEST_ERROR:     http.StatusBadRequest,
	MISSING_FIELDS_ERROR:      http.StatusBadRequest,
	NOT_FOUND_ERROR:           http.StatusNotFound,
	ALREADY_EXISTS_ERROR:      http.StatusConflict,
	CONFLICT_ERROR:            http.StatusConflict,
	UNPROCESSABLE_ERROR:       http.StatusUnprocessableEntity,
	INVALID_CREDENTIALS_ERROR: http.StatusUnauthorized,
	ACCESS_DENIED_ERROR:       http.StatusUnauthorized,
	MISSING_PERMISSION_ERROR:  http.StatusForbidden,
	ACCOUNT_INACTIVE_ERROR:    http.StatusForbidden,
	DATABASE_ERROR:            http.StatusInternalServerError,
	INTERNAL_ERROR:            http.StatusInternalServerError,
}

var ErrorMessages = map[int]string{
	INVALID_REQUEST_ERROR:     "Invalid request format",
	MISSING_FIELDS_ERROR:      "Required fields are missing",
	NOT_FOUND_ERROR:           "Resource not found",
	ALREADY_EXISTS_ERROR:      "Resource already exists",
	CONFLICT_ERROR:            "Operation conflicts with current resource state",
	UNPROCESSABLE_ERROR:       "Request could not be processed due to business rules",
	INVALID_CREDENTIALS_ERROR: "Invalid credentials provided",
	ACCESS_DENIED_ERROR:       "Authentication required",
	MISSING_PERMISSION_ERROR:  "Insufficient permissions",
	ACCOUNT_INACTIVE_ERROR:    "Inactive user account",
	DATABASE_ERROR:            "Database operation failed",
	INTERNAL_ERROR:            "Internal server error",
}
