package server

import (
	"net/http"

	"github.com/F4nk1/educca/backend/source/common"
	"github.com/F4nk1/educca/backend/source/model"
)

func (s *Server) listOrganizaciones(w http.ResponseWriter, r *http.Request) {
	items, err := s.Service.ListOrganizaciones(r.Context())
	if err != nil {
		writeServiceError(w, r, err, "Organizacion not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusOK, items)
}

func (s *Server) getOrganizacion(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}
	item, err := s.Service.GetOrganizacion(r.Context(), id)
	if err != nil {
		writeServiceError(w, r, err, "Organizacion not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusOK, item)
}

func (s *Server) createOrganizacion(w http.ResponseWriter, r *http.Request) {
	var req model.Organizacion
	if !decodeJSON(w, r, &req) {
		return
	}
	if code, msg := validateOrganizacion(&req); code != 0 {
		common.WriteErrorMessage(w, code, msg)
		return
	}
	id, err := s.Service.CreateOrganizacion(r.Context(), &req)
	if err != nil {
		writeServiceError(w, r, err, "Organizacion not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusCreated, map[string]int64{"id": id})
}

func (s *Server) updateOrganizacion(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}
	var req model.Organizacion
	if !decodeJSON(w, r, &req) {
		return
	}
	if code, msg := validateOrganizacion(&req); code != 0 {
		common.WriteErrorMessage(w, code, msg)
		return
	}
	req.Id = id
	if err := s.Service.UpdateOrganizacion(r.Context(), &req); err != nil {
		writeServiceError(w, r, err, "Organizacion not found")
		return
	}
	common.WriteSuccessResponse(w, http.StatusOK, "Organizacion updated")
}

func (s *Server) deleteOrganizacion(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}
	if err := s.Service.DeleteOrganizacion(r.Context(), id); err != nil {
		writeServiceError(w, r, err, "Organizacion not found")
		return
	}
	common.WriteSuccessResponse(w, http.StatusOK, "Organizacion deleted")
}
