package server

import (
	"net/http"

	"github.com/F4nk1/educca/backend/source/common"
	"github.com/F4nk1/educca/backend/source/model"
)

func (s *Server) listMetasAnuales(w http.ResponseWriter, r *http.Request) {
	anio, ok := parseOptionalAnio(w, r)
	if !ok {
		return
	}
	items, err := s.Service.ListMetasAnuales(r.Context(), anio)
	if err != nil {
		writeServiceError(w, r, err, "Meta anual not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusOK, items)
}

func (s *Server) getMetaAnual(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}
	item, err := s.Service.GetMetaAnual(r.Context(), id)
	if err != nil {
		writeServiceError(w, r, err, "Meta anual not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusOK, item)
}

func (s *Server) createMetaAnual(w http.ResponseWriter, r *http.Request) {
	var req model.MetaAnual
	if !decodeJSON(w, r, &req) {
		return
	}
	if err := validateMetaAnual(&req); err != nil {
		common.WriteErrorMessage(w, common.MISSING_FIELDS_ERROR, err.Error())
		return
	}
	id, err := s.Service.CreateMetaAnual(r.Context(), &req)
	if err != nil {
		writeServiceError(w, r, err, "Meta anual not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusCreated, map[string]int64{"id": id})
}

func (s *Server) updateMetaAnual(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}
	var req model.MetaAnual
	if !decodeJSON(w, r, &req) {
		return
	}
	if err := validateMetaAnual(&req); err != nil {
		common.WriteErrorMessage(w, common.MISSING_FIELDS_ERROR, err.Error())
		return
	}
	req.Id = id
	if err := s.Service.UpdateMetaAnual(r.Context(), &req); err != nil {
		writeServiceError(w, r, err, "Meta anual not found")
		return
	}
	common.WriteSuccessResponse(w, http.StatusOK, "Meta anual updated")
}

func (s *Server) deleteMetaAnual(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}
	if err := s.Service.DeleteMetaAnual(r.Context(), id); err != nil {
		writeServiceError(w, r, err, "Meta anual not found")
		return
	}
	common.WriteSuccessResponse(w, http.StatusOK, "Meta anual deleted")
}
