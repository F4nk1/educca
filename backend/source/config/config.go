package config

import (
	"fmt"
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	Server   Server   `json:"server"`
	Database Database `json:"database"`
}

func getEnv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

func NewConfiguration() *Config {
	_ = godotenv.Load()
	_ = godotenv.Load("backend/.env")

	return &Config{
		Server: Server{
			Port:          getEnv("SERVER_PORT", "8080"),
			AccessSecret:  getEnv("ACCESS_SECRET", "default_dev_access_secret_educca"),
			RefreshSecret: getEnv("REFRESH_SECRET", "default_dev_refresh_secret_educca"),
		},
		Database: Database{
			Driver:   "pgx",
			Name:     getEnv("DB_NAME", "educca"),
			UserName: getEnv("DB_USER", "postgres"),
			Password: os.Getenv("DB_PASSWORD"),
			Host:     getEnv("DB_HOST", "localhost"),
			Port:     getEnv("DB_PORT", "5432"),
		},
	}
}

func (c *Config) GetStringDBConnection() string {
	return fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=disable",
		c.Database.UserName,
		c.Database.Password,
		c.Database.Host,
		c.Database.Port,
		c.Database.Name,
	)
}
