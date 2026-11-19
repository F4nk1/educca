package config

import (
	"errors"
	"fmt"
	"net/url"
	"os"
	"strconv"
	"strings"

	"github.com/joho/godotenv"
)

const (
	defaultDevAccessSecret  = "default_dev_access_secret_educca"
	defaultDevRefreshSecret = "default_dev_refresh_secret_educca"
	defaultDevQRSecret      = "default_dev_qr_secret_educca"
	exampleAccessSecret     = "super_secret_jwt_access_key_change_in_prod"
	exampleRefreshSecret    = "super_secret_jwt_refresh_key_change_in_prod"
	exampleQRSecret         = "super_secret_qr_hmac_key_change_in_prod"
)

type Config struct {
	Server   Server   `json:"server"`
	Database Database `json:"database"`
}

func getEnv(key, fallback string) string {
	if value := strings.TrimSpace(os.Getenv(key)); value != "" {
		return value
	}
	return fallback
}

func parseOrigins(raw string) []string {
	parts := strings.Split(raw, ",")
	origins := make([]string, 0, len(parts))
	for _, p := range parts {
		if trimmed := strings.TrimSpace(p); trimmed != "" {
			origins = append(origins, trimmed)
		}
	}
	return origins
}

func NewConfiguration() *Config {
	_ = godotenv.Load()
	_ = godotenv.Load("backend/.env")

	env := strings.ToLower(getEnv("APP_ENV", "development"))
	isDev := env == "development" || env == "dev" || env == "test"

	accessFallback := ""
	refreshFallback := ""
	qrFallback := ""
	if isDev {
		accessFallback = defaultDevAccessSecret
		refreshFallback = defaultDevRefreshSecret
		qrFallback = defaultDevQRSecret
	}

	qrTTL := 300
	if rawTTL := strings.TrimSpace(os.Getenv("QR_TTL_SECONDS")); rawTTL != "" {
		if parsed, err := strconv.Atoi(rawTTL); err == nil && parsed >= 30 {
			qrTTL = parsed
		}
	}

	defaultOrigins := "https://educca.cocorium.online,http://educca.cocorium.online,http://localhost:3000,http://localhost:5173,http://localhost:8080"

	return &Config{
		Server: Server{
			Port:                 getEnv("SERVER_PORT", "8080"),
			Env:                  env,
			AccessSecret:         getEnv("ACCESS_SECRET", accessFallback),
			RefreshSecret:        getEnv("REFRESH_SECRET", refreshFallback),
			QRSecret:             getEnv("QR_SECRET", qrFallback),
			QRTTLSeconds:         qrTTL,
			PrivacyPolicyVersion: getEnv("PRIVACY_POLICY_VERSION", "v1.0-2026"),
			AllowedOrigins:       parseOrigins(getEnv("CORS_ALLOWED_ORIGINS", defaultOrigins)),
		},
		Database: Database{
			Driver:   "pgx",
			Name:     getEnv("DB_NAME", "educca"),
			UserName: getEnv("DB_USER", "postgres"),
			Password: os.Getenv("DB_PASSWORD"),
			Host:     getEnv("DB_HOST", "localhost"),
			Port:     getEnv("DB_PORT", "5432"),
			SSLMode:  getEnv("DB_SSLMODE", "disable"),
		},
	}
}

func (c *Config) Validate() error {
	env := strings.ToLower(c.Server.Env)
	isDev := env == "development" || env == "dev" || env == "test"
	if !isDev {
		if isInsecureSecret(c.Server.AccessSecret, defaultDevAccessSecret, exampleAccessSecret) {
			return errors.New("ACCESS_SECRET must be set to a strong secret outside development")
		}
		if isInsecureSecret(c.Server.RefreshSecret, defaultDevRefreshSecret, exampleRefreshSecret) {
			return errors.New("REFRESH_SECRET must be set to a strong secret outside development")
		}
		if isInsecureSecret(c.Server.QRSecret, defaultDevQRSecret, exampleQRSecret) {
			return errors.New("QR_SECRET must be set to a strong secret outside development")
		}
	}
	return nil
}

func isInsecureSecret(val string, forbidden ...string) bool {
	trimmed := strings.TrimSpace(val)
	if len(trimmed) < 16 {
		return true
	}
	for _, f := range forbidden {
		if trimmed == f {
			return true
		}
	}
	return false
}

func (c *Config) GetStringDBConnection() string {
	sslMode := strings.TrimSpace(c.Database.SSLMode)
	if sslMode == "" {
		sslMode = "disable"
	}
	u := &url.URL{
		Scheme:   "postgres",
		User:     url.UserPassword(c.Database.UserName, c.Database.Password),
		Host:     fmt.Sprintf("%s:%s", c.Database.Host, c.Database.Port),
		Path:     "/" + c.Database.Name,
		RawQuery: "sslmode=" + url.QueryEscape(sslMode),
	}
	return u.String()
}
