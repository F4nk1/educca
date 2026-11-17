# Variables
BACKEND_DIR=backend
DB_SCRIPT=./database/AmbiData.sh

.DEFAULT_GOAL := help
.PHONY: help setup backend-setup db-setup db-build run_b clean

# Show available targets
help:
	@echo "Available targets:"
	@echo "  setup          - Rebuild Go dependencies and reset PostgreSQL DB from zero"
	@echo "  backend-setup  - Tidy and download Go dependencies"
	@echo "  db-setup       - Generate AmbiData.sql and recreate PostgreSQL DB from zero"
	@echo "  db-build       - Generate consolidated database/AmbiData.sql"
	@echo "  run_b          - Start backend server"
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

# Generate AmbiData.sql only
db-build:
	@$(DB_SCRIPT)

# Run backend server
run_b:
	@echo "Starting backend server..."
	@cd $(BACKEND_DIR) && go run .

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BACKEND_DIR)/bin $(BACKEND_DIR)/main
