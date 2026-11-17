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

func NewConfiguration() *Config {
	_ = godotenv.Load()
	_ = godotenv.Load("backend/.env")

	port := os.Getenv("SERVER_PORT")
	if port == "" {
		port = "8080"
	}

	dbPort := os.Getenv("DB_PORT")
	if dbPort == "" {
		dbPort = "3306"
	}

	return &Config{
		Server: Server{
			Port: port,
		},
		Database: Database{
			Driver:   "mysql",
			Name:     os.Getenv("DB_NAME"),
			UserName: os.Getenv("DB_USER"),
			Password: os.Getenv("DB_PASSWORD"),
			Protocol: "tcp",
			Host:     os.Getenv("DB_HOST"),
			Port:     dbPort,
		},
	}
}

func (c *Config) GetStringDBConnection() string {
	return fmt.Sprintf("%s:%s@%s(%s:%s)/%s?parseTime=true&loc=Local&charset=utf8mb4",
		c.Database.UserName,
		c.Database.Password,
		c.Database.Protocol,
		c.Database.Host,
		c.Database.Port,
		c.Database.Name,
	)
}
