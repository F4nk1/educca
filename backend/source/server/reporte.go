package server

import (
	"net/http"

	"github.com/F4nk1/educca/backend/source/common"
)

func (s *Server) getReporteAvanceMetas(w http.ResponseWriter, r *http.Request) {
	anio, ok := parseOptionalAnio(w, r)
	if !ok {
		return
	}
	items, err := s.Service.GetReporteAvanceMetas(r.Context(), anio)
	if err != nil {
		writeServiceError(w, r, err, "Report data not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusOK, items)
}
