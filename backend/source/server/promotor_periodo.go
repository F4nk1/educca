package server

import (
	"net/http"

	"github.com/F4nk1/educca/backend/source/common"
	"github.com/F4nk1/educca/backend/source/model"
)

func (s *Server) listPromotoresPeriodo(w http.ResponseWriter, r *http.Request) {
	anio, ok := parseOptionalAnio(w, r)
	if !ok {
		return
	}
	items, err := s.Service.ListPromotoresPeriodo(r.Context(), anio)
	if err != nil {
		writeServiceError(w, r, err, "Promotor periodo not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusOK, items)
}

func (s *Server) getPromotorPeriodo(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}
	item, err := s.Service.GetPromotorPeriodo(r.Context(), id)
	if err != nil {
		writeServiceError(w, r, err, "Promotor periodo not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusOK, item)
}

func (s *Server) createPromotorPeriodo(w http.ResponseWriter, r *http.Request) {
	var req model.PromotorPeriodo
	if !decodeJSON(w, r, &req) {
		return
	}
	if err := validatePromotorPeriodo(&req, false); err != nil {
		common.WriteErrorMessage(w, common.MISSING_FIELDS_ERROR, err.Error())
		return
	}
	id, err := s.Service.CreatePromotorPeriodo(r.Context(), &req)
	if err != nil {
		writeServiceError(w, r, err, "Promotor periodo not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusCreated, map[string]int64{"id": id})
}

func (s *Server) updatePromotorPeriodo(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}
	var req model.PromotorPeriodo
	if !decodeJSON(w, r, &req) {
		return
	}
	if err := validatePromotorPeriodo(&req, true); err != nil {
		common.WriteErrorMessage(w, common.MISSING_FIELDS_ERROR, err.Error())
		return
	}
	req.Id = id
	if err := s.Service.UpdatePromotorPeriodo(r.Context(), &req); err != nil {
		writeServiceError(w, r, err, "Promotor periodo not found")
		return
	}
	common.WriteSuccessResponse(w, http.StatusOK, "Promotor periodo updated")
}

func (s *Server) deletePromotorPeriodo(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}
	if err := s.Service.DeletePromotorPeriodo(r.Context(), id); err != nil {
		writeServiceError(w, r, err, "Promotor periodo not found")
		return
	}
	common.WriteSuccessResponse(w, http.StatusOK, "Promotor periodo deleted")
}
