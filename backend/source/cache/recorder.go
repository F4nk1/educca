package cache

import "net/http"

type CachedResponse struct {
	StatusCode int
	Body       []byte
}

type StatusRecorder struct {
	http.ResponseWriter
	StatusCode int
}

func NewStatusRecorder(w http.ResponseWriter) *StatusRecorder {
	return &StatusRecorder{
		ResponseWriter: w,
		StatusCode:     http.StatusOK,
	}
}

func (r *StatusRecorder) WriteHeader(statusCode int) {
	r.StatusCode = statusCode
	r.ResponseWriter.WriteHeader(statusCode)
}

type Recorder struct {
	http.ResponseWriter
	StatusCode int
	Body       []byte
}

func NewRecorder(w http.ResponseWriter) *Recorder {
	return &Recorder{
		ResponseWriter: w,
		StatusCode:     http.StatusOK,
	}
}

func (r *Recorder) WriteHeader(statusCode int) {
	r.StatusCode = statusCode
	r.ResponseWriter.WriteHeader(statusCode)
}

func (r *Recorder) Write(data []byte) (int, error) {
	r.Body = append(r.Body, data...)
	return r.ResponseWriter.Write(data)
}
