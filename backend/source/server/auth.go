package server

import (
	"net/http"
	"strings"
	"time"

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

type registerRequest struct {
	Dni                    string  `json:"dni"`
	Nombres                string  `json:"nombres"`
	Apellidos              string  `json:"apellidos"`
	Sexo                   string  `json:"sexo"`
	FechaNacimiento        string  `json:"fecha_nacimiento"`
	Telefono               *string `json:"telefono"`
	Email                  string  `json:"email"`
	Password               string  `json:"password"`
	Categoria              string  `json:"categoria"`
	ConsentimientoAceptado bool    `json:"consentimiento_aceptado"`
	ConsentimientoVersion  string  `json:"consentimiento_version"`
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

	persona, err := s.Service.Login(r.Context(), strings.TrimSpace(req.Identificador), req.Password)
	if err != nil {
		writeServiceError(w, r, err, "Persona not found")
		return
	}

	tokens, err := s.Auth.GenerateAuthToken(persona.Id)
	if err != nil {
		tracer.Errorf(r.Context(), "Failed to generate tokens for persona %d: %s", persona.Id, err)
		common.WriteErrorResponse(w, common.INTERNAL_ERROR)
		return
	}

	common.WriteObjectResponse(w, http.StatusOK, tokens)
}

func (s *Server) register(w http.ResponseWriter, r *http.Request) {
	var req registerRequest
	if !decodeJSON(w, r, &req) {
		return
	}

	if !req.ConsentimientoAceptado {
		common.WriteErrorMessage(w, common.UNPROCESSABLE_ERROR, "Debe aceptar expresamente el consentimiento informado de datos personales (LPDP)")
		return
	}

	emailTrimmed := strings.ToLower(strings.TrimSpace(req.Email))
	categoriaTrimmed := strings.ToUpper(strings.TrimSpace(req.Categoria))
	if emailTrimmed == "" || req.Password == "" || categoriaTrimmed == "" || strings.TrimSpace(req.FechaNacimiento) == "" {
		common.WriteErrorMessage(w, common.MISSING_FIELDS_ERROR, "dni, nombres, apellidos, sexo, fecha_nacimiento, email, password and categoria are required")
		return
	}

	if code, msg := validatePersonaFields(req.Dni, req.Nombres, req.Apellidos, req.Sexo, &emailTrimmed, &categoriaTrimmed); code != 0 {
		common.WriteErrorMessage(w, code, msg)
		return
	}

	if len(req.Password) < 8 {
		common.WriteErrorMessage(w, common.INVALID_REQUEST_ERROR, "password must be at least 8 characters long")
		return
	}

	fechaNac, err := parseDate(strings.TrimSpace(req.FechaNacimiento))
	if err != nil {
		common.WriteErrorMessage(w, common.INVALID_REQUEST_ERROR, "Invalid fecha_nacimiento (expected YYYY-MM-DD or RFC3339)")
		return
	}

	if !isAdultAt(fechaNac, time.Now()) {
		common.WriteErrorMessage(w, common.UNPROCESSABLE_ERROR, "El registro directo en plataforma requiere mayoría de edad (>= 18 años) conforme a la LPDP")
		return
	}

	policyVersion := strings.TrimSpace(req.ConsentimientoVersion)
	if policyVersion == "" {
		if s.Config != nil && s.Config.Server.PrivacyPolicyVersion != "" {
			policyVersion = s.Config.Server.PrivacyPolicyVersion
		} else {
			policyVersion = "v1.0-2026"
		}
	}

	p := &model.Persona{
		Dni:             strings.TrimSpace(req.Dni),
		Nombres:         strings.TrimSpace(req.Nombres),
		Apellidos:       strings.TrimSpace(req.Apellidos),
		Sexo:            req.Sexo,
		FechaNacimiento: fechaNac,
		Telefono:        normalizeOptionalString(req.Telefono),
		Email:           &emailTrimmed,
		Categoria:       &categoriaTrimmed,
		Activo:          true,
	}

	id, err := s.Service.RegisterCapacitando(r.Context(), p, req.Password, policyVersion)
	if err != nil {
		writeServiceError(w, r, err, "Role capacitando not found")
		return
	}

	s.Cache.Flush()

	tokens, err := s.Auth.GenerateAuthToken(id)
	if err != nil {
		tracer.Errorf(r.Context(), "Failed to generate tokens for registered persona %d: %s", id, err)
		common.WriteErrorResponse(w, common.INTERNAL_ERROR)
		return
	}

	common.WriteObjectResponse(w, http.StatusCreated, map[string]any{
		"id":                     id,
		"rol":                    "capacitando",
		"categoria":              categoriaTrimmed,
		"consentimiento_version": policyVersion,
		"access_token":           tokens.AccessToken,
		"refresh_token":          tokens.RefreshToken,
		"expires_in":             tokens.ExpiresIn,
		"token_type":             tokens.TokenType,
	})
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
	if !persona.Activo || persona.Anonimizado {
		common.WriteErrorResponse(w, common.ACCOUNT_INACTIVE_ERROR)
		return
	}

	tokens, err := s.Auth.GenerateAuthToken(claims.PersonaId)
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
	if !persona.Activo || persona.Anonimizado {
		common.WriteErrorResponse(w, common.ACCOUNT_INACTIVE_ERROR)
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
