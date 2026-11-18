package middleware

import (
	"fmt"
	"net/http"

	"github.com/gorilla/mux"

	"github.com/F4nk1/educca/backend/source/cache"
	"github.com/F4nk1/educca/backend/source/common"
	"github.com/F4nk1/educca/backend/source/model"
	"github.com/F4nk1/educca/backend/source/tracer"
)

func Cache(c cache.Cache) mux.MiddlewareFunc {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ctx := r.Context()
			if r.Method != http.MethodGet {
				recorder := cache.NewStatusRecorder(w)
				next.ServeHTTP(recorder, r)
				if recorder.StatusCode >= http.StatusOK && recorder.StatusCode < http.StatusBadRequest {
					c.Flush()
				}
				return
			}

			key := r.URL.RequestURI()
			if claims, ok := ctx.Value(common.UserContextKey).(*model.Claims); ok {
				key = fmt.Sprintf("%d:%s", claims.PersonaId, key)
			}

			if cached, found := c.Get(key); found {
				if entry, ok := cached.(cache.CachedResponse); ok {
					tracer.Debugf(ctx, "Cached response served for %s", key)
					w.Header().Set("Content-Type", common.ContentTypeJSON)
					w.WriteHeader(entry.StatusCode)
					_, _ = w.Write(entry.Body)
					return
				}
			}

			recorder := cache.NewRecorder(w)
			next.ServeHTTP(recorder, r)
			if recorder.StatusCode >= http.StatusOK && recorder.StatusCode < http.StatusMultipleChoices {
				bodyCopy := make([]byte, len(recorder.Body))
				copy(bodyCopy, recorder.Body)
				c.Set(key, cache.CachedResponse{
					StatusCode: recorder.StatusCode,
					Body:       bodyCopy,
				}, cache.DefaultTTL)
			}
		})
	}
}
