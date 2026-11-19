package middleware

import (
	"net/http"
	"strings"
)

var defaultAllowedOrigins = []string{
	"https://educca.cocorium.online",
	"http://educca.cocorium.online",
	"http://localhost:3000",
	"http://localhost:5173",
	"http://localhost:8080",
}

func Cors(next http.Handler) http.Handler {
	return CorsWithOrigins(defaultAllowedOrigins)(next)
}

func CorsWithOrigins(allowedOrigins []string) func(http.Handler) http.Handler {
	allowedSet := make(map[string]bool, len(allowedOrigins))
	allowAll := false
	for _, o := range allowedOrigins {
		trimmed := strings.TrimSpace(o)
		if trimmed == "*" {
			allowAll = true
		} else if trimmed != "" {
			allowedSet[trimmed] = true
		}
	}
	if len(allowedSet) == 0 && !allowAll {
		for _, o := range defaultAllowedOrigins {
			allowedSet[o] = true
		}
	}

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.Header().Add("Vary", "Origin")
			origin := strings.TrimSpace(r.Header.Get("Origin"))
			if origin != "" {
				if allowAll {
					w.Header().Set("Access-Control-Allow-Origin", "*")
				} else if allowedSet[origin] {
					w.Header().Set("Access-Control-Allow-Origin", origin)
					w.Header().Set("Access-Control-Allow-Credentials", "true")
				}
			}
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "X-Requested-With, Content-Type, Authorization")

			if r.Method == http.MethodOptions {
				w.WriteHeader(http.StatusNoContent)
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}
