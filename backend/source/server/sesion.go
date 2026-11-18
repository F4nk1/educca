package server

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/F4nk1/educca/backend/source/auth"
	"github.com/F4nk1/educca/backend/source/common"
	"github.com/F4nk1/educca/backend/source/model"
)

type sesionRequest struct {
	MetaAnualId     int64  `json:"meta_anual_id"`
	OrganizacionId  *int64 `json:"organizacion_id"`
	ResponsableId   int64  `json:"responsable_id"`
	Titulo          string `json:"titulo"`
	Modalidad       string `json:"modalidad"`
	EjeTematico     string `json:"eje_tematico"`
	FechaInicio     string `json:"fecha_inicio"`
	DuracionMinutos int16  `json:"duracion_minutos"`
	CupoMaximo      int    `json:"cupo_maximo"`
}

func qrCacheKey(sesionId int64) string {
	return fmt.Sprintf("qr:sesion:%d", sesionId)
}

func (s *Server) getActiveQRState(sesionId int64) (*model.QRSessionState, int64, bool) {
	if s.QRCache == nil {
		return nil, 0, false
	}
	raw, found := s.QRCache.Get(qrCacheKey(sesionId))
	if !found {
		return nil, 0, false
	}
	state, ok := raw.(model.QRSessionState)
	if !ok {
		return nil, 0, false
	}
	remaining := int64(time.Until(state.ExpiresAt).Seconds())
	if remaining <= 0 {
		s.QRCache.Delete(qrCacheKey(sesionId))
		return nil, 0, false
	}
	return &state, remaining, true
}

func (s *Server) canManageSesionExecution(ctx *http.Request, sesion *model.Sesion, personaId int64) (bool, error) {
	if sesion.ResponsableId == personaId {
		return true, nil
	}
	if ok, err := s.Service.HasPermission(ctx.Context(), personaId, common.PermSesionesCrear); err != nil || ok {
		return ok, err
	}
	return s.Service.HasPermission(ctx.Context(), personaId, common.PermSesionesValidar)
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
	if raw := strings.TrimSpace(r.URL.Query().Get("estado")); raw != "" {
		if !validEstadosSesion[raw] {
			common.WriteErrorMessage(w, common.INVALID_REQUEST_ERROR, "Invalid 'estado' query parameter")
			return
		}
		estado = &raw
	}

	var ejeTematico *string
	if raw := strings.TrimSpace(r.URL.Query().Get("eje_tematico")); raw != "" {
		if !validEjesTematicos[raw] {
			common.WriteErrorMessage(w, common.INVALID_REQUEST_ERROR, "Invalid 'eje_tematico' query parameter")
			return
		}
		ejeTematico = &raw
	}

	var organizacionId *int64
	if raw := r.URL.Query().Get("organizacion_id"); raw != "" {
		val, err := strconv.ParseInt(raw, 10, 64)
		if err != nil || val <= 0 {
			common.WriteErrorMessage(w, common.INVALID_REQUEST_ERROR, "Invalid 'organizacion_id' query parameter")
			return
		}
		organizacionId = &val
	}

	items, err := s.Service.ListSesiones(r.Context(), metaId, estado, ejeTematico, organizacionId)
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
	eje := strings.ToUpper(strings.TrimSpace(req.EjeTematico))
	if code, msg := validateSesionFields(req.MetaAnualId, req.ResponsableId, req.Titulo, req.Modalidad, eje, req.DuracionMinutos, req.CupoMaximo); code != 0 {
		common.WriteErrorMessage(w, code, msg)
		return
	}
	if strings.TrimSpace(req.FechaInicio) == "" {
		common.WriteErrorMessage(w, common.MISSING_FIELDS_ERROR, "fecha_inicio is required")
		return
	}
	fechaInicio, err := parseDateTime(req.FechaInicio)
	if err != nil {
		common.WriteErrorMessage(w, common.INVALID_REQUEST_ERROR, err.Error())
		return
	}

	if eje == "" {
		eje = "SEGREGACION_RECICLA"
	}
	cupo := req.CupoMaximo
	if cupo <= 0 {
		cupo = 50
	}

	ses := &model.Sesion{
		MetaAnualId:     req.MetaAnualId,
		OrganizacionId:  req.OrganizacionId,
		ResponsableId:   req.ResponsableId,
		Titulo:          strings.TrimSpace(req.Titulo),
		Modalidad:       req.Modalidad,
		EjeTematico:     eje,
		FechaInicio:     fechaInicio,
		DuracionMinutos: req.DuracionMinutos,
		CupoMaximo:      cupo,
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
	eje := strings.ToUpper(strings.TrimSpace(req.EjeTematico))
	if code, msg := validateSesionFields(req.MetaAnualId, req.ResponsableId, req.Titulo, req.Modalidad, eje, req.DuracionMinutos, req.CupoMaximo); code != 0 {
		common.WriteErrorMessage(w, code, msg)
		return
	}
	if strings.TrimSpace(req.FechaInicio) == "" {
		common.WriteErrorMessage(w, common.MISSING_FIELDS_ERROR, "fecha_inicio is required")
		return
	}
	fechaInicio, err := parseDateTime(req.FechaInicio)
	if err != nil {
		common.WriteErrorMessage(w, common.INVALID_REQUEST_ERROR, err.Error())
		return
	}

	if eje == "" {
		eje = "SEGREGACION_RECICLA"
	}
	cupo := req.CupoMaximo
	if cupo <= 0 {
		cupo = 50
	}

	ses := &model.Sesion{
		Id:              id,
		MetaAnualId:     req.MetaAnualId,
		OrganizacionId:  req.OrganizacionId,
		ResponsableId:   req.ResponsableId,
		Titulo:          strings.TrimSpace(req.Titulo),
		Modalidad:       req.Modalidad,
		EjeTematico:     eje,
		FechaInicio:     fechaInicio,
		DuracionMinutos: req.DuracionMinutos,
		CupoMaximo:      cupo,
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
	if strings.TrimSpace(req.Estado) == "" {
		common.WriteErrorMessage(w, common.MISSING_FIELDS_ERROR, "estado is required")
		return
	}
	if !validEstadosSesion[req.Estado] {
		common.WriteErrorMessage(w, common.INVALID_REQUEST_ERROR, "Invalid sesion estado")
		return
	}

	claims, ok := r.Context().Value(common.UserContextKey).(*model.Claims)
	if !ok {
		common.WriteErrorResponse(w, common.ACCESS_DENIED_ERROR)
		return
	}

	if req.Estado == "VALIDADA" || req.Estado == "CANCELADA" {
		allowed, err := s.Service.HasPermission(r.Context(), claims.PersonaId, common.PermSesionesValidar)
		if err != nil {
			writeServiceError(w, r, err, "Persona not found")
			return
		}
		if !allowed {
			common.WriteErrorResponse(w, common.MISSING_PERMISSION_ERROR)
			return
		}
	} else {
		hasCrear, err := s.Service.HasPermission(r.Context(), claims.PersonaId, common.PermSesionesCrear)
		if err != nil {
			writeServiceError(w, r, err, "Persona not found")
			return
		}
		if !hasCrear {
			hasQR, err := s.Service.HasPermission(r.Context(), claims.PersonaId, common.PermSesionesQR)
			if err != nil {
				writeServiceError(w, r, err, "Persona not found")
				return
			}
			if !hasQR {
				common.WriteErrorResponse(w, common.MISSING_PERMISSION_ERROR)
				return
			}
			ses, err := s.Service.GetSesion(r.Context(), id)
			if err != nil {
				writeServiceError(w, r, err, "Sesion not found")
				return
			}
			if ses.ResponsableId != claims.PersonaId {
				common.WriteErrorResponse(w, common.MISSING_PERMISSION_ERROR)
				return
			}
		}
	}

	if err := s.Service.ChangeSesionEstado(r.Context(), id, req.Estado); err != nil {
		writeServiceError(w, r, err, "Sesion not found")
		return
	}

	if s.QRCache != nil {
		s.QRCache.Delete(qrCacheKey(id))
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
	if s.QRCache != nil {
		s.QRCache.Delete(qrCacheKey(id))
	}
	common.WriteSuccessResponse(w, http.StatusOK, "Sesion deleted")
}

func (s *Server) generateSesionQR(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}

	claims, ok := r.Context().Value(common.UserContextKey).(*model.Claims)
	if !ok {
		common.WriteErrorResponse(w, common.ACCESS_DENIED_ERROR)
		return
	}

	ses, err := s.Service.GetSesion(r.Context(), id)
	if err != nil {
		writeServiceError(w, r, err, "Sesion not found")
		return
	}

	canManage, err := s.canManageSesionExecution(r, ses, claims.PersonaId)
	if err != nil {
		writeServiceError(w, r, err, "Persona not found")
		return
	}
	if !canManage {
		common.WriteErrorResponse(w, common.MISSING_PERMISSION_ERROR)
		return
	}

	if ses.Modalidad != "PRESENCIAL" {
		common.WriteErrorMessage(w, common.UNPROCESSABLE_ERROR, "Solo se puede generar código QR para sesiones presenciales")
		return
	}
	if ses.Estado == "VALIDADA" || ses.Estado == "CANCELADA" {
		common.WriteErrorMessage(w, common.CONFLICT_ERROR, "No se puede generar QR para una sesión en estado "+ses.Estado)
		return
	}
	if ses.OrganizacionId == nil {
		common.WriteErrorMessage(w, common.UNPROCESSABLE_ERROR, "La sesión no tiene una sede (organización) asignada")
		return
	}

	org, err := s.Service.GetOrganizacion(r.Context(), *ses.OrganizacionId)
	if err != nil {
		writeServiceError(w, r, err, "Organizacion not found")
		return
	}
	if org.Latitud == nil || org.Longitud == nil {
		common.WriteErrorMessage(w, common.UNPROCESSABLE_ERROR, "La sede de la sesión no tiene coordenadas GPS (latitud/longitud) configuradas")
		return
	}

	ttlSeconds := 300
	if s.Config != nil && s.Config.Server.QRTTLSeconds >= 30 {
		ttlSeconds = s.Config.Server.QRTTLSeconds
	}

	if r.Body != nil {
		var req struct {
			TTLSeconds int `json:"ttl_seconds"`
		}
		err := json.NewDecoder(http.MaxBytesReader(w, r.Body, maxJSONBodyBytes)).Decode(&req)
		if err != nil && !errors.Is(err, io.EOF) {
			common.WriteErrorResponse(w, common.INVALID_REQUEST_ERROR)
			return
		}
		if req.TTLSeconds > 0 {
			if req.TTLSeconds < 30 || req.TTLSeconds > 3600 {
				common.WriteErrorMessage(w, common.INVALID_REQUEST_ERROR, "ttl_seconds must be between 30 and 3600")
				return
			}
			ttlSeconds = req.TTLSeconds
		}
	}

	nonce, err := auth.GenerateNonce()
	if err != nil {
		common.WriteErrorResponse(w, common.INTERNAL_ERROR)
		return
	}

	ttl := time.Duration(ttlSeconds) * time.Second
	tokenStr, expiresAt, err := s.Auth.GenerateQRToken(id, nonce, ttl)
	if err != nil {
		common.WriteErrorResponse(w, common.INTERNAL_ERROR)
		return
	}

	state := model.QRSessionState{
		SesionId:  id,
		Token:     tokenStr,
		Nonce:     nonce,
		ExpiresAt: expiresAt,
	}
	s.QRCache.Set(qrCacheKey(id), state, ttl)

	common.WriteObjectResponse(w, http.StatusOK, map[string]any{
		"sesion_id":          id,
		"qr_token":           tokenStr,
		"expires_at":         expiresAt,
		"segundos_restantes": ttlSeconds,
	})
}

func (s *Server) getSesionQR(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}

	if _, err := s.Service.GetSesion(r.Context(), id); err != nil {
		writeServiceError(w, r, err, "Sesion not found")
		return
	}

	state, remaining, active := s.getActiveQRState(id)
	if !active {
		common.WriteErrorMessage(w, common.NOT_FOUND_ERROR, "No hay un código QR vigente para esta sesión")
		return
	}

	common.WriteObjectResponse(w, http.StatusOK, map[string]any{
		"sesion_id":          id,
		"qr_token":           state.Token,
		"expires_at":         state.ExpiresAt,
		"segundos_restantes": remaining,
	})
}

func (s *Server) revokeSesionQR(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}

	claims, ok := r.Context().Value(common.UserContextKey).(*model.Claims)
	if !ok {
		common.WriteErrorResponse(w, common.ACCESS_DENIED_ERROR)
		return
	}

	ses, err := s.Service.GetSesion(r.Context(), id)
	if err != nil {
		writeServiceError(w, r, err, "Sesion not found")
		return
	}

	canManage, err := s.canManageSesionExecution(r, ses, claims.PersonaId)
	if err != nil {
		writeServiceError(w, r, err, "Persona not found")
		return
	}
	if !canManage {
		common.WriteErrorResponse(w, common.MISSING_PERMISSION_ERROR)
		return
	}

	if s.QRCache != nil {
		s.QRCache.Delete(qrCacheKey(id))
	}
	common.WriteSuccessResponse(w, http.StatusOK, "Código QR revocado")
}

func (s *Server) getSesionMonitoreo(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int64](w, r, "id", 64)
	if !ok {
		return
	}

	ses, err := s.Service.GetSesion(r.Context(), id)
	if err != nil {
		writeServiceError(w, r, err, "Sesion not found")
		return
	}

	asistencias, err := s.Service.ListAsistencias(r.Context(), id)
	if err != nil {
		writeServiceError(w, r, err, "Sesion not found")
		return
	}

	_, remaining, qrActive := s.getActiveQRState(id)

	common.WriteObjectResponse(w, http.StatusOK, model.SesionMonitoreo{
		Sesion:              *ses,
		QRActivo:            qrActive,
		QRSegundosRestantes: remaining,
		TotalInscritos:      ses.InscritosActuales,
		TotalAsistentes:     len(asistencias),
		Asistencias:         asistencias,
	})
}
