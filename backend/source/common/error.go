package common

import (
	"encoding/json"
	"net/http"
)

type Response struct {
	HttpStatusCode int    `json:"httpStatusCode"`
	ErrorCode      int    `json:"errorCode,omitempty"`
	Message        string `json:"message"`
}

func writeJSON(w http.ResponseWriter, httpStatus int, data any) {
	w.Header().Set("Content-Type", ContentTypeJSON)
	w.WriteHeader(httpStatus)
	_ = json.NewEncoder(w).Encode(data)
}

func WriteErrorResponse(w http.ResponseWriter, errorCode int) {
	msg, ok := ErrorMessages[errorCode]
	if !ok {
		msg = ErrorMessages[INTERNAL_ERROR]
	}
	WriteErrorMessage(w, errorCode, msg)
}

func WriteErrorMessage(w http.ResponseWriter, errorCode int, message string) {
	httpStatus, ok := ErrorCodes[errorCode]
	if !ok {
		httpStatus = http.StatusInternalServerError
	}
	writeJSON(w, httpStatus, Response{
		HttpStatusCode: httpStatus,
		ErrorCode:      errorCode,
		Message:        message,
	})
}

func WriteSuccessResponse(w http.ResponseWriter, httpStatus int, message string) {
	writeJSON(w, httpStatus, Response{
		HttpStatusCode: httpStatus,
		Message:        message,
	})
}

func WriteObjectResponse(w http.ResponseWriter, httpStatus int, data any) {
	writeJSON(w, httpStatus, data)
}
