package main

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/F4nk1/educca/backend/source/config"
	"github.com/F4nk1/educca/backend/source/database"
	"github.com/F4nk1/educca/backend/source/server"
	"github.com/F4nk1/educca/backend/source/service"
	"github.com/F4nk1/educca/backend/source/tracer"
)

func main() {
	ctx := context.Background()
	cfg := config.NewConfiguration()
	if err := cfg.Validate(); err != nil {
		tracer.Fatal(ctx, err)
	}

	tracer.Infof(ctx, "Starting database host '%s:%s'", cfg.Database.Host, cfg.Database.Port)

	conn, err := database.NewDataBase(ctx, cfg)
	if err != nil {
		tracer.Fatal(ctx, err)
	}
	defer conn.Close()

	svc := service.NewService(conn)
	srv := server.NewServer(svc, cfg)

	serverHost := fmt.Sprintf(":%s", cfg.Server.Port)
	httpServer := &http.Server{
		Addr:              serverHost,
		Handler:           srv.Handler,
		ReadTimeout:       10 * time.Second,
		ReadHeaderTimeout: 5 * time.Second,
		WriteTimeout:      15 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	tracer.Infof(ctx, "Starting server on %s", serverHost)
	tracer.Fatal(ctx, httpServer.ListenAndServe())
}
