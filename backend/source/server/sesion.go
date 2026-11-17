package server

import (
	"net/http"
	"strconv"

	"github.com/F4nk1/educca/backend/source/common"
	"github.com/F4nk1/educca/backend/source/model"
)

type sesionRequest struct {
	MetaAnualId     int64  `json:"meta_anual_id"`
	OrganizacionId  *int64 `json:"organizacion_id"`
	ResponsableId   int64  `json:"responsable_id"`
	Titulo          string `json:"titulo"`
	Modalidad       string `json:"modalidad"`
	FechaInicio     string `json:"fecha_inicio"`
	DuracionMinutos int16  `json:"duracion_minutos"`
}

func (s *Server) listSesiones(w http.ResponseWriter, r *http.Request) {
	var metaId *int64
	if raw := r.URL.Query().Get("meta_anual_id"); raw != "" {
		val, err := strconv.ParseInt(raw, 10, 64)
		if err != nil || val <= 0 {
			common.WriteErrorMessage(w, common.INVALID_REQUEST_ERROR, "Invalid 'meta_anual_id' query parameter")
			return
		}
		metaId = &val
	}

	var estado *string
	if raw := r.URL.Query().Get("estado"); raw != "" {
		if !validEstadosSesion[raw] {
			common.WriteErrorMessage(w, common.INVALID_REQUEST_ERROR, "Invalid 'estado' query parameter")
			return
		}
		estado = &raw
	}

	items, err := s.Service.ListSesiones(r.Context(), metaId, estado)
	if err != nil {
		writeServiceError(w, r, err, "Sesion not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusOK, items)
}

func (s *Server) getSesion(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}
	item, err := s.Service.GetSesion(r.Context(), id)
	if err != nil {
		writeServiceError(w, r, err, "Sesion not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusOK, item)
}

func (s *Server) createSesion(w http.ResponseWriter, r *http.Request) {
	var req sesionRequest
	if !decodeJSON(w, r, &req) {
		return
	}
	if err := validateSesionFields(req.MetaAnualId, req.ResponsableId, req.Titulo, req.Modalidad, req.DuracionMinutos); err != nil {
		common.WriteErrorMessage(w, common.MISSING_FIELDS_ERROR, err.Error())
		return
	}
	fechaInicio, err := parseDateTime(req.FechaInicio)
	if err != nil {
		common.WriteErrorMessage(w, common.INVALID_REQUEST_ERROR, err.Error())
		return
	}

	ses := &model.Sesion{
		MetaAnualId:     req.MetaAnualId,
		OrganizacionId:  req.OrganizacionId,
		ResponsableId:   req.ResponsableId,
		Titulo:          req.Titulo,
		Modalidad:       req.Modalidad,
		FechaInicio:     fechaInicio,
		DuracionMinutos: req.DuracionMinutos,
	}

	id, err := s.Service.CreateSesion(r.Context(), ses)
	if err != nil {
		writeServiceError(w, r, err, "Sesion not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusCreated, map[string]int64{"id": id})
}

func (s *Server) updateSesion(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}
	var req sesionRequest
	if !decodeJSON(w, r, &req) {
		return
	}
	if err := validateSesionFields(req.MetaAnualId, req.ResponsableId, req.Titulo, req.Modalidad, req.DuracionMinutos); err != nil {
		common.WriteErrorMessage(w, common.MISSING_FIELDS_ERROR, err.Error())
		return
	}
	fechaInicio, err := parseDateTime(req.FechaInicio)
	if err != nil {
		common.WriteErrorMessage(w, common.INVALID_REQUEST_ERROR, err.Error())
		return
	}

	ses := &model.Sesion{
		Id:              id,
		MetaAnualId:     req.MetaAnualId,
		OrganizacionId:  req.OrganizacionId,
		ResponsableId:   req.ResponsableId,
		Titulo:          req.Titulo,
		Modalidad:       req.Modalidad,
		FechaInicio:     fechaInicio,
		DuracionMinutos: req.DuracionMinutos,
	}
	if err := s.Service.UpdateSesion(r.Context(), ses); err != nil {
		writeServiceError(w, r, err, "Sesion not found")
		return
	}
	common.WriteSuccessResponse(w, http.StatusOK, "Sesion updated")
}

func (s *Server) changeSesionEstado(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}
	var req struct {
		Estado string `json:"estado"`
	}
	if !decodeJSON(w, r, &req) {
		return
	}
	if !validEstadosSesion[req.Estado] {
		common.WriteErrorMessage(w, common.INVALID_REQUEST_ERROR, "Invalid sesion estado")
		return
	}

	if req.Estado == "VALIDADA" || req.Estado == "CANCELADA" {
		claims, ok := r.Context().Value(common.UserContextKey).(*model.Claims)
		if !ok {
			common.WriteErrorResponse(w, common.ACCESS_DENIED_ERROR)
			return
		}
		allowed, err := s.Service.HasPermission(r.Context(), claims.PersonaId, common.PermSesionesValidar)
		if err != nil {
			writeServiceError(w, r, err, "Persona not found")
			return
		}
		if !allowed {
			common.WriteErrorResponse(w, common.MISSING_PERMISSION_ERROR)
			return
		}
	}

	if err := s.Service.ChangeSesionEstado(r.Context(), id, req.Estado); err != nil {
		writeServiceError(w, r, err, "Sesion not found")
		return
	}
	common.WriteSuccessResponse(w, http.StatusOK, "Sesion estado updated")
}

func (s *Server) deleteSesion(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}
	if err := s.Service.DeleteSesion(r.Context(), id); err != nil {
		writeServiceError(w, r, err, "Sesion not found")
		return
	}
	common.WriteSuccessResponse(w, http.StatusOK, "Sesion deleted")
}
