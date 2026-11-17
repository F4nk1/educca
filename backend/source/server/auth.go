package server

import (
	"net/http"
	"strings"

	"github.com/F4nk1/educca/backend/source/common"
	"github.com/F4nk1/educca/backend/source/model"
	"github.com/F4nk1/educca/backend/source/tracer"
)

type loginRequest struct {
	Identificador string `json:"identificador"`
	Password      string `json:"password"`
}

type refreshRequest struct {
	RefreshToken string `json:"refresh_token"`
}

func (s *Server) login(w http.ResponseWriter, r *http.Request) {
	var req loginRequest
	if !decodeJSON(w, r, &req) {
		return
	}
	if strings.TrimSpace(req.Identificador) == "" || req.Password == "" {
		common.WriteErrorResponse(w, common.MISSING_FIELDS_ERROR)
		return
	}

	persona, roles, permisos, err := s.Service.Login(r.Context(), strings.TrimSpace(req.Identificador), req.Password)
	if err != nil {
		writeServiceError(w, r, err, "Persona not found")
		return
	}

	tokens, err := s.Auth.GenerateAuthToken(persona.Id, roles, permisos)
	if err != nil {
		tracer.Errorf(r.Context(), "Failed to generate tokens for persona %d: %s", persona.Id, err)
		common.WriteErrorResponse(w, common.INTERNAL_ERROR)
		return
	}

	common.WriteObjectResponse(w, http.StatusOK, tokens)
}

func (s *Server) refreshToken(w http.ResponseWriter, r *http.Request) {
	var req refreshRequest
	if !decodeJSON(w, r, &req) {
		return
	}
	if strings.TrimSpace(req.RefreshToken) == "" {
		common.WriteErrorResponse(w, common.MISSING_FIELDS_ERROR)
		return
	}

	claims, err := s.Auth.ValidateRefreshToken(req.RefreshToken)
	if err != nil {
		common.WriteErrorResponse(w, common.INVALID_CREDENTIALS_ERROR)
		return
	}

	persona, err := s.Service.GetPersona(r.Context(), claims.PersonaId)
	if err != nil {
		writeServiceError(w, r, err, "Persona not found")
		return
	}
	if !persona.Activo {
		common.WriteErrorMessage(w, common.ACCESS_DENIED_ERROR, "Inactive user account")
		return
	}

	roles, permisos, err := s.Service.GetPersonaRolesPermisos(r.Context(), claims.PersonaId)
	if err != nil {
		writeServiceError(w, r, err, "Persona not found")
		return
	}

	tokens, err := s.Auth.GenerateAuthToken(claims.PersonaId, roles, permisos)
	if err != nil {
		tracer.Errorf(r.Context(), "Failed to refresh tokens for persona %d: %s", claims.PersonaId, err)
		common.WriteErrorResponse(w, common.INTERNAL_ERROR)
		return
	}

	common.WriteObjectResponse(w, http.StatusOK, tokens)
}

func (s *Server) me(w http.ResponseWriter, r *http.Request) {
	claims, ok := r.Context().Value(common.UserContextKey).(*model.Claims)
	if !ok {
		common.WriteErrorResponse(w, common.ACCESS_DENIED_ERROR)
		return
	}

	persona, err := s.Service.GetPersona(r.Context(), claims.PersonaId)
	if err != nil {
		writeServiceError(w, r, err, "Persona not found")
		return
	}

	roles, permisos, err := s.Service.GetPersonaRolesPermisos(r.Context(), claims.PersonaId)
	if err != nil {
		writeServiceError(w, r, err, "Persona not found")
		return
	}

	common.WriteObjectResponse(w, http.StatusOK, map[string]any{
		"persona":  persona,
		"roles":    roles,
		"permisos": permisos,
	})
}
