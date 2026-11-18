package server

import (
	"net/http"
	"strings"

	"github.com/F4nk1/educca/backend/source/common"
	"github.com/F4nk1/educca/backend/source/model"
)

type personaRequest struct {
	Dni             string  `json:"dni"`
	Nombres         string  `json:"nombres"`
	Apellidos       string  `json:"apellidos"`
	Sexo            string  `json:"sexo"`
	FechaNacimiento string  `json:"fecha_nacimiento"`
	Telefono        *string `json:"telefono"`
	Email           *string `json:"email"`
	Password        string  `json:"password"`
	Activo          *bool   `json:"activo"`
}

func (s *Server) listPersonas(w http.ResponseWriter, r *http.Request) {
	personas, err := s.Service.ListPersonas(r.Context())
	if err != nil {
		writeServiceError(w, r, err, "Persona not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusOK, personas)
}

func (s *Server) getPersona(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}
	persona, err := s.Service.GetPersona(r.Context(), id)
	if err != nil {
		writeServiceError(w, r, err, "Persona not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusOK, persona)
}

func (s *Server) createPersona(w http.ResponseWriter, r *http.Request) {
	var req personaRequest
	if !decodeJSON(w, r, &req) {
		return
	}
	if code, msg := validatePersonaFields(req.Dni, req.Nombres, req.Apellidos, req.Sexo); code != 0 {
		common.WriteErrorMessage(w, code, msg)
		return
	}
	if strings.TrimSpace(req.FechaNacimiento) == "" {
		common.WriteErrorMessage(w, common.MISSING_FIELDS_ERROR, "fecha_nacimiento is required")
		return
	}
	fechaNac, err := parseDate(req.FechaNacimiento)
	if err != nil {
		common.WriteErrorMessage(w, common.INVALID_REQUEST_ERROR, "Invalid fecha_nacimiento (expected YYYY-MM-DD or RFC3339)")
		return
	}

	activo := true
	if req.Activo != nil {
		activo = *req.Activo
	}

	p := &model.Persona{
		Dni:             strings.TrimSpace(req.Dni),
		Nombres:         strings.TrimSpace(req.Nombres),
		Apellidos:       strings.TrimSpace(req.Apellidos),
		Sexo:            req.Sexo,
		FechaNacimiento: fechaNac,
		Telefono:        normalizeOptionalString(req.Telefono),
		Email:           normalizeOptionalString(req.Email),
		Activo:          activo,
	}

	id, err := s.Service.CreatePersona(r.Context(), p, req.Password)
	if err != nil {
		writeServiceError(w, r, err, "Persona not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusCreated, map[string]int64{"id": id})
}

func (s *Server) updatePersona(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}
	var req personaRequest
	if !decodeJSON(w, r, &req) {
		return
	}
	if code, msg := validatePersonaFields(req.Dni, req.Nombres, req.Apellidos, req.Sexo); code != 0 {
		common.WriteErrorMessage(w, code, msg)
		return
	}
	if strings.TrimSpace(req.FechaNacimiento) == "" {
		common.WriteErrorMessage(w, common.MISSING_FIELDS_ERROR, "fecha_nacimiento is required")
		return
	}
	fechaNac, err := parseDate(req.FechaNacimiento)
	if err != nil {
		common.WriteErrorMessage(w, common.INVALID_REQUEST_ERROR, "Invalid fecha_nacimiento (expected YYYY-MM-DD or RFC3339)")
		return
	}

	p := &model.Persona{
		Id:              id,
		Dni:             strings.TrimSpace(req.Dni),
		Nombres:         strings.TrimSpace(req.Nombres),
		Apellidos:       strings.TrimSpace(req.Apellidos),
		Sexo:            req.Sexo,
		FechaNacimiento: fechaNac,
		Telefono:        normalizeOptionalString(req.Telefono),
		Email:           normalizeOptionalString(req.Email),
	}
	if err := s.Service.UpdatePersona(r.Context(), p); err != nil {
		writeServiceError(w, r, err, "Persona not found")
		return
	}
	common.WriteSuccessResponse(w, http.StatusOK, "Persona updated")
}

func (s *Server) setPersonaActivo(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}
	var req struct {
		Activo *bool `json:"activo"`
	}
	if !decodeJSON(w, r, &req) {
		return
	}
	if req.Activo == nil {
		common.WriteErrorResponse(w, common.MISSING_FIELDS_ERROR)
		return
	}
	if err := s.Service.SetPersonaActivo(r.Context(), id, *req.Activo); err != nil {
		writeServiceError(w, r, err, "Persona not found")
		return
	}
	common.WriteSuccessResponse(w, http.StatusOK, "Persona status updated")
}

func (s *Server) setPersonaPassword(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}

	claims, ok := r.Context().Value(common.UserContextKey).(*model.Claims)
	if !ok {
		common.WriteErrorResponse(w, common.ACCESS_DENIED_ERROR)
		return
	}

	if claims.PersonaId != id {
		allowed, err := s.Service.HasPermission(r.Context(), claims.PersonaId, common.PermRolesGestionar)
		if err != nil {
			writeServiceError(w, r, err, "Persona not found")
			return
		}
		if !allowed {
			common.WriteErrorResponse(w, common.MISSING_PERMISSION_ERROR)
			return
		}
	}

	var req struct {
		Password string `json:"password"`
	}
	if !decodeJSON(w, r, &req) {
		return
	}
	if req.Password == "" {
		common.WriteErrorResponse(w, common.MISSING_FIELDS_ERROR)
		return
	}
	if err := s.Service.SetPersonaPassword(r.Context(), id, req.Password); err != nil {
		writeServiceError(w, r, err, "Persona not found")
		return
	}
	common.WriteSuccessResponse(w, http.StatusOK, "Password updated")
}

func (s *Server) listPersonaRoles(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}
	roles, err := s.Service.ListPersonaRoles(r.Context(), id)
	if err != nil {
		writeServiceError(w, r, err, "Persona not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusOK, roles)
}

func (s *Server) assignPersonaRol(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}
	var req struct {
		RolId int16 `json:"rol_id"`
	}
	if !decodeJSON(w, r, &req) {
		return
	}
	if req.RolId <= 0 {
		common.WriteErrorResponse(w, common.MISSING_FIELDS_ERROR)
		return
	}
	if err := s.Service.AssignPersonaRol(r.Context(), id, req.RolId); err != nil {
		writeServiceError(w, r, err, "Persona or rol not found")
		return
	}
	common.WriteSuccessResponse(w, http.StatusCreated, "Role assigned to persona")
}

func (s *Server) removePersonaRol(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}
	rolId, ok := parseID[int16](w, r, "rol_id", 16)
	if !ok {
		return
	}
	if err := s.Service.RemovePersonaRol(r.Context(), id, rolId); err != nil {
		writeServiceError(w, r, err, "Persona role assignment not found")
		return
	}
	common.WriteSuccessResponse(w, http.StatusOK, "Role removed from persona")
}
