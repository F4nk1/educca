package server

import (
	"net/http"

	"github.com/F4nk1/educca/backend/source/common"
	"github.com/F4nk1/educca/backend/source/model"
)

func (s *Server) createInscripcion(w http.ResponseWriter, r *http.Request) {
	sesionId, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}

	claims, ok := r.Context().Value(common.UserContextKey).(*model.Claims)
	if !ok {
		common.WriteErrorResponse(w, common.ACCESS_DENIED_ERROR)
		return
	}

	id, err := s.Service.CreateInscripcion(r.Context(), sesionId, claims.PersonaId)
	if err != nil {
		writeServiceError(w, r, err, "Sesion not found")
		return
	}

	common.WriteObjectResponse(w, http.StatusCreated, map[string]any{
		"id":         id,
		"sesion_id":  sesionId,
		"persona_id": claims.PersonaId,
		"estado":     "INSCRITO",
	})
}

func (s *Server) cancelMyInscripcion(w http.ResponseWriter, r *http.Request) {
	sesionId, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}

	claims, ok := r.Context().Value(common.UserContextKey).(*model.Claims)
	if !ok {
		common.WriteErrorResponse(w, common.ACCESS_DENIED_ERROR)
		return
	}

	if err := s.Service.CancelInscripcion(r.Context(), sesionId, claims.PersonaId); err != nil {
		writeServiceError(w, r, err, "Inscripcion not found")
		return
	}

	common.WriteSuccessResponse(w, http.StatusOK, "Inscripción cancelada")
}

func (s *Server) listInscripcionesBySesion(w http.ResponseWriter, r *http.Request) {
	sesionId, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}

	items, err := s.Service.ListInscripcionesBySesion(r.Context(), sesionId)
	if err != nil {
		writeServiceError(w, r, err, "Sesion not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusOK, items)
}

func (s *Server) listMyInscripciones(w http.ResponseWriter, r *http.Request) {
	claims, ok := r.Context().Value(common.UserContextKey).(*model.Claims)
	if !ok {
		common.WriteErrorResponse(w, common.ACCESS_DENIED_ERROR)
		return
	}

	items, err := s.Service.ListInscripcionesByPersona(r.Context(), claims.PersonaId)
	if err != nil {
		writeServiceError(w, r, err, "Persona not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusOK, items)
}
