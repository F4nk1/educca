package model

import "github.com/golang-jwt/jwt/v5"

type Claims struct {
	PersonaId int64    `json:"persona_id"`
	Roles     []string `json:"roles"`
	Permisos  []string `json:"permisos"`
	jwt.RegisteredClaims
}
