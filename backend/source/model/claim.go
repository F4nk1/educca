package model

import (
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type Claims struct {
	PersonaId int64  `json:"persona_id"`
	TokenUse  string `json:"token_use"`
	jwt.RegisteredClaims
}

type QRClaims struct {
	SesionId int64  `json:"sesion_id"`
	Nonce    string `json:"nonce"`
	TokenUse string `json:"token_use"`
	jwt.RegisteredClaims
}

type QRSessionState struct {
	SesionId  int64     `json:"sesion_id"`
	Token     string    `json:"qr_token"`
	Nonce     string    `json:"nonce"`
	ExpiresAt time.Time `json:"expires_at"`
}
