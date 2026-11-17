package middleware

import (
	"context"
	"net/http"

	"github.com/gorilla/mux"

	"github.com/F4nk1/educca/backend/source/common"
	"github.com/F4nk1/educca/backend/source/model"
	"github.com/F4nk1/educca/backend/source/tracer"
)

type PermissionChecker interface {
	HasPermission(ctx context.Context, personaId int64, permiso string) (bool, error)
}

func Permission(checker PermissionChecker) mux.MiddlewareFunc {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ctx := r.Context()
			required := common.GetRequiredPermission(r)
			if required == "" {
				next.ServeHTTP(w, r)
				return
			}

			claims, ok := ctx.Value(common.UserContextKey).(*model.Claims)
			if !ok {
				tracer.Warnf(ctx, "Missing claims in context")
				common.WriteErrorResponse(w, common.ACCESS_DENIED_ERROR)
				return
			}

			allowed, err := checker.HasPermission(ctx, claims.PersonaId, required)
			if err != nil {
				tracer.Errorf(ctx, "Permission check error for persona %d: %s", claims.PersonaId, err)
				common.WriteErrorResponse(w, common.DATABASE_ERROR)
				return
			}
			if !allowed {
				tracer.Warnf(ctx, "Permission '%s' denied for persona %d", required, claims.PersonaId)
				common.WriteErrorResponse(w, common.MISSING_PERMISSION_ERROR)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}
