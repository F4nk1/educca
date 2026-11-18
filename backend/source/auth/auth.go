package auth

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"time"

	"github.com/F4nk1/educca/backend/source/model"
	"github.com/golang-jwt/jwt/v5"
)

const (
	MinutesDuration = 15
	DaysDuration    = 7

	AccessTokenDuration  = MinutesDuration * time.Minute
	RefreshTokenDuration = DaysDuration * 24 * time.Hour
	TokenType            = "Bearer"
	Issuer               = "educca-api"

	TokenUseAccess    = "access"
	TokenUseRefresh   = "refresh"
	TokenUseQRCheckin = "qr_checkin"
)

type Auth struct {
	accessSecret  []byte
	refreshSecret []byte
	qrSecret      []byte
}

func NewAuth(accessSecret, refreshSecret string, qrSecret ...string) *Auth {
	qrKey := accessSecret + ":qr"
	if len(qrSecret) > 0 && qrSecret[0] != "" {
		qrKey = qrSecret[0]
	}
	return &Auth{
		accessSecret:  []byte(accessSecret),
		refreshSecret: []byte(refreshSecret),
		qrSecret:      []byte(qrKey),
	}
}

func (a *Auth) GenerateAuthToken(personaId int64) (*model.Token, error) {
	now := time.Now()
	accessExpiry := now.Add(AccessTokenDuration)
	refreshExpiry := now.Add(RefreshTokenDuration)

	accessToken, err := a.generateToken(personaId, TokenUseAccess, accessExpiry, a.accessSecret)
	if err != nil {
		return nil, fmt.Errorf("failed to generate access token: %v", err)
	}

	refreshToken, err := a.generateToken(personaId, TokenUseRefresh, refreshExpiry, a.refreshSecret)
	if err != nil {
		return nil, fmt.Errorf("failed to generate refresh token: %v", err)
	}

	return &model.Token{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresIn:    int64(AccessTokenDuration.Seconds()),
		TokenType:    TokenType,
	}, nil
}

func (a *Auth) generateToken(personaId int64, tokenUse string, expiry time.Time, secret []byte) (string, error) {
	now := time.Now()
	claims := model.Claims{
		PersonaId: personaId,
		TokenUse:  tokenUse,
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    Issuer,
			Subject:   fmt.Sprintf("%d", personaId),
			ExpiresAt: jwt.NewNumericDate(expiry),
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(secret)
}

func (a *Auth) ValidateAccessToken(tokenString string) (*model.Claims, error) {
	return a.validateToken(tokenString, TokenUseAccess, a.accessSecret)
}

func (a *Auth) ValidateRefreshToken(tokenString string) (*model.Claims, error) {
	return a.validateToken(tokenString, TokenUseRefresh, a.refreshSecret)
}

func (a *Auth) validateToken(tokenString, expectedUse string, secret []byte) (*model.Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &model.Claims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("invalid signing method")
		}
		return secret, nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to parse token: %v", err)
	}

	if claims, ok := token.Claims.(*model.Claims); ok && token.Valid && claims.TokenUse == expectedUse {
		return claims, nil
	}

	return nil, errors.New("invalid token")
}

func GenerateNonce() (string, error) {
	b := make([]byte, 16)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}

func (a *Auth) GenerateQRToken(sesionId int64, nonce string, ttl time.Duration) (string, time.Time, error) {
	if ttl <= 0 {
		ttl = 5 * time.Minute
	}
	now := time.Now()
	expiry := now.Add(ttl)

	claims := model.QRClaims{
		SesionId: sesionId,
		Nonce:    nonce,
		TokenUse: TokenUseQRCheckin,
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    Issuer,
			Subject:   fmt.Sprintf("sesion:%d", sesionId),
			ExpiresAt: jwt.NewNumericDate(expiry),
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signed, err := token.SignedString(a.qrSecret)
	if err != nil {
		return "", time.Time{}, err
	}
	return signed, expiry, nil
}

func (a *Auth) ValidateQRToken(tokenString string) (*model.QRClaims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &model.QRClaims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("invalid signing method")
		}
		return a.qrSecret, nil
	})
	if err != nil {
		return nil, fmt.Errorf("failed to parse QR token: %v", err)
	}

	if claims, ok := token.Claims.(*model.QRClaims); ok && token.Valid && claims.TokenUse == TokenUseQRCheckin && claims.SesionId > 0 && claims.Nonce != "" {
		return claims, nil
	}
	return nil, errors.New("invalid QR token")
}
