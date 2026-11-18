package server

import (
	"fmt"
	"math"
	"net/http"
	"strings"

	"github.com/F4nk1/educca/backend/source/common"
	"github.com/F4nk1/educca/backend/source/model"
	"github.com/F4nk1/educca/backend/source/service"
)

type checkInQRRequest struct {
	QRToken  string   `json:"qr_token"`
	Latitud  *float64 `json:"latitud"`
	Longitud *float64 `json:"longitud"`
}

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

func (s *Server) listMyAsistencias(w http.ResponseWriter, r *http.Request) {
	claims, ok := r.Context().Value(common.UserContextKey).(*model.Claims)
	if !ok {
		common.WriteErrorResponse(w, common.ACCESS_DENIED_ERROR)
		return
	}
	items, err := s.Service.ListAsistenciasByPersona(r.Context(), claims.PersonaId)
	if err != nil {
		writeServiceError(w, r, err, "Persona not found")
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

func (s *Server) checkInQR(w http.ResponseWriter, r *http.Request) {
	claims, ok := r.Context().Value(common.UserContextKey).(*model.Claims)
	if !ok {
		common.WriteErrorResponse(w, common.ACCESS_DENIED_ERROR)
		return
	}

	var req checkInQRRequest
	if !decodeJSON(w, r, &req) {
		return
	}
	if strings.TrimSpace(req.QRToken) == "" || req.Latitud == nil || req.Longitud == nil {
		common.WriteErrorMessage(w, common.MISSING_FIELDS_ERROR, "qr_token, latitud and longitud are required")
		return
	}
	if code, msg := validateCoordinates(req.Latitud, req.Longitud); code != 0 {
		common.WriteErrorMessage(w, code, msg)
		return
	}

	qrClaims, err := s.Auth.ValidateQRToken(strings.TrimSpace(req.QRToken))
	if err != nil {
		common.WriteErrorMessage(w, common.UNPROCESSABLE_ERROR, "Código QR inválido o expirado")
		return
	}

	state, _, active := s.getActiveQRState(qrClaims.SesionId)
	if !active || state.Nonce != qrClaims.Nonce {
		common.WriteErrorMessage(w, common.UNPROCESSABLE_ERROR, "El código QR de la sesión ha expirado o fue rotado/revocado")
		return
	}

	ses, err := s.Service.GetSesion(r.Context(), qrClaims.SesionId)
	if err != nil {
		writeServiceError(w, r, err, "Sesion not found")
		return
	}
	if ses.Modalidad != "PRESENCIAL" {
		common.WriteErrorMessage(w, common.UNPROCESSABLE_ERROR, "El check-in QR y GPS solo está disponible para sesiones presenciales")
		return
	}
	if ses.Estado == "VALIDADA" || ses.Estado == "CANCELADA" {
		common.WriteErrorMessage(w, common.CONFLICT_ERROR, "No se puede registrar asistencia en una sesión en estado "+ses.Estado)
		return
	}
	if ses.OrganizacionId == nil {
		common.WriteErrorMessage(w, common.UNPROCESSABLE_ERROR, "La sesión no cuenta con una sede georreferenciada")
		return
	}

	org, err := s.Service.GetOrganizacion(r.Context(), *ses.OrganizacionId)
	if err != nil {
		writeServiceError(w, r, err, "Organizacion not found")
		return
	}
	if org.Latitud == nil || org.Longitud == nil {
		common.WriteErrorMessage(w, common.UNPROCESSABLE_ERROR, "La sede de la sesión no tiene coordenadas GPS configuradas")
		return
	}

	radio := org.RadioMetros
	if radio <= 0 {
		radio = 80
	}

	distancia := service.HaversineMeters(*req.Latitud, *req.Longitud, *org.Latitud, *org.Longitud)
	distanciaRedondeada := math.Round(distancia*100) / 100

	if distancia > float64(radio) {
		common.WriteErrorMessage(
			w,
			common.UNPROCESSABLE_ERROR,
			fmt.Sprintf("Ubicación fuera del radio permitido de la sede: %.2f m (máximo %d m)", distanciaRedondeada, radio),
		)
		return
	}

	if err := s.Service.CheckInQR(r.Context(), ses.Id, claims.PersonaId, distanciaRedondeada); err != nil {
		writeServiceError(w, r, err, "Sesion or persona not found")
		return
	}

	common.WriteObjectResponse(w, http.StatusCreated, map[string]any{
		"message":          "Asistencia presencial registrada exitosamente",
		"sesion_id":        ses.Id,
		"persona_id":       claims.PersonaId,
		"metodo_registro":  "QR_GPS",
		"distancia_metros": distanciaRedondeada,
		"radio_metros":     radio,
	})
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
