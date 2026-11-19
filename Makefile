# Variables
BACKEND_DIR=backend
DB_SCRIPT=./database/AmbiData.sh
COMPOSE=docker compose

.DEFAULT_GOAL := help
.PHONY: help setup backend-setup db-setup run_b clean docker-up docker-down docker-reset docker-logs tunnel

# Show available targets
help:
	@echo "Options :"
	@echo "  setup          - Rebuild Go dependencies and reset PostgreSQL DB from zero"
	@echo "  backend-setup  - Tidy and download Go dependencies"
	@echo "  db-setup       - Generate AmbiData.sql and recreate PostgreSQL DB from zero"
	@echo "  run_b          - Start backend server locally"
	@echo "  docker-up      - Build and start PostgreSQL, Go API, Web & Cloudflare Tunnel (educca.cocorium.online)"
	@echo "  docker-down    - Stop Docker Compose stack"
	@echo "  docker-reset   - Recreate AmbiData.sql, wipe Docker volumes and start stack fresh"
	@echo "  docker-logs    - Tail Docker Compose logs"
	@echo "  clean          - Remove build artifacts"

# Full setup (rebuilds dependencies and database from zero)
setup: backend-setup db-setup
	@echo "Setup complete!"

# Tidy and download Go dependencies
backend-setup:
	@echo "Setting up backend dependencies..."
	@cd $(BACKEND_DIR) && go mod tidy && go mod download

# Generate and rebuild PostgreSQL database from zero
db-setup:
	@echo "Rebuilding PostgreSQL database..."
	@$(DB_SCRIPT) --apply

# Run backend server
run_b:
	@echo "Starting backend server..."
	@cd $(BACKEND_DIR) && go run .

# Start full Docker Compose stack + Cloudflare Tunnel
docker-up:
	@$(DB_SCRIPT)
	@$(COMPOSE) up -d --build

# Stop Docker Compose stack
docker-down:
	@$(COMPOSE) down

# Reset Docker Compose stack and volumes from zero
docker-reset:
	@$(DB_SCRIPT)
	@$(COMPOSE) down -v
	@$(COMPOSE) up -d --build

# Follow Docker Compose logs
docker-logs:
	@$(COMPOSE) logs -f

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BACKEND_DIR)/bin $(BACKEND_DIR)/main
