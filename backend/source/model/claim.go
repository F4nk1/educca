package model

import "github.com/golang-jwt/jwt/v5"

type Claims struct {
	PersonaId int64  `json:"persona_id"`
	TokenUse  string `json:"token_use"`
	jwt.RegisteredClaims
}
