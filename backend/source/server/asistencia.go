package server

import (
	"net/http"

	"github.com/F4nk1/educca/backend/source/common"
	"github.com/F4nk1/educca/backend/source/model"
)

func (s *Server) listAsistencias(w http.ResponseWriter, r *http.Request) {
	sesionId, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}
	items, err := s.Service.ListAsistencias(r.Context(), sesionId)
	if err != nil {
		writeServiceError(w, r, err, "Sesion not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusOK, items)
}

func (s *Server) upsertAsistencia(w http.ResponseWriter, r *http.Request) {
	sesionId, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}
	var req model.Asistencia
	if !decodeJSON(w, r, &req) {
		return
	}
	req.SesionId = sesionId
	if code, msg := validateAsistencia(&req); code != 0 {
		common.WriteErrorMessage(w, code, msg)
		return
	}
	if err := s.Service.UpsertAsistencia(r.Context(), &req); err != nil {
		writeServiceError(w, r, err, "Sesion or persona not found")
		return
	}
	common.WriteSuccessResponse(w, http.StatusOK, "Asistencia saved")
}

func (s *Server) deleteAsistencia(w http.ResponseWriter, r *http.Request) {
	sesionId, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}
	personaId, ok := parseID[int64](w, r, "persona_id", 64)
	if !ok {
		return
	}
	if err := s.Service.DeleteAsistencia(r.Context(), sesionId, personaId); err != nil {
		writeServiceError(w, r, err, "Asistencia not found")
		return
	}
	common.WriteSuccessResponse(w, http.StatusOK, "Asistencia deleted")
}
