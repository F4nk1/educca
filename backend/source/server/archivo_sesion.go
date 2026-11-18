package server

import (
	"net/http"
	"strings"

	"github.com/F4nk1/educca/backend/source/common"
	"github.com/F4nk1/educca/backend/source/model"
)

func (s *Server) listArchivosSesion(w http.ResponseWriter, r *http.Request) {
	sesionId, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}
	items, err := s.Service.ListArchivosSesion(r.Context(), sesionId)
	if err != nil {
		writeServiceError(w, r, err, "Sesion not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusOK, items)
}

func (s *Server) createArchivoSesion(w http.ResponseWriter, r *http.Request) {
	sesionId, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}
	var req model.ArchivoSesion
	if !decodeJSON(w, r, &req) {
		return
	}
	req.SesionId = sesionId
	if code, msg := validateArchivoSesion(&req); code != 0 {
		common.WriteErrorMessage(w, code, msg)
		return
	}
	req.UrlArchivo = strings.TrimSpace(req.UrlArchivo)
	id, err := s.Service.CreateArchivoSesion(r.Context(), &req)
	if err != nil {
		writeServiceError(w, r, err, "Sesion not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusCreated, map[string]int64{"id": id})
}

func (s *Server) deleteArchivoSesion(w http.ResponseWriter, r *http.Request) {
	sesionId, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}
	archivoId, ok := parseID[int64](w, r, "archivo_id", 64)
	if !ok {
		return
	}
	if err := s.Service.DeleteArchivoSesion(r.Context(), archivoId, sesionId); err != nil {
		writeServiceError(w, r, err, "Archivo sesion not found")
		return
	}
	common.WriteSuccessResponse(w, http.StatusOK, "Archivo sesion deleted")
}
