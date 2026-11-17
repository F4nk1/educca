# Variables
BINARY_NAME=educca
BACKEND_DIR=backend
BUILD_DIR=$(BACKEND_DIR)/bin
ENV_FILE=$(BACKEND_DIR)/.env
ENV_EXAMPLE=$(BACKEND_DIR)/.env.example
DB_SCRIPT=./database/AmbiData.sh

.DEFAULT_GOAL := help
.PHONY: help setup env-setup deps-setup db-setup db-build db-apply lint build run_b clean

# Show available targets
help:
	@echo "Available targets:"
	@echo "  setup     - Full project setup (.env + Go deps + PostgreSQL DB)"
	@echo "  db-build  - Generate consolidated database/AmbiData.sql"
	@echo "  db-apply  - Generate and apply AmbiData.sql to PostgreSQL"
	@echo "  lint      - Format and check Go code"
	@echo "  build     - Lint and compile backend binary"
	@echo "  run_b     - Start backend server"
	@echo "  clean     - Remove build artifacts"

# Full setup
setup: env-setup deps-setup db-setup
	@echo "Setup complete!"

# Create backend/.env from example if missing
env-setup:
	@if [ ! -f "$(ENV_FILE)" ]; then \
		cp "$(ENV_EXAMPLE)" "$(ENV_FILE)"; \
		echo "Created $(ENV_FILE) from $(ENV_EXAMPLE)"; \
	else \
		echo "$(ENV_FILE) already exists, keeping current values"; \
	fi

# Install Go dependencies
deps-setup:
	@echo "Installing Go dependencies..."
	@cd $(BACKEND_DIR) && go mod download

# Generate and apply PostgreSQL schema + seed data
db-setup:
	@echo "Setting up PostgreSQL database..."
	@$(DB_SCRIPT) --apply

# Generate AmbiData.sql only
db-build:
	@$(DB_SCRIPT)

# Generate and apply AmbiData.sql
db-apply:
	@$(DB_SCRIPT) --apply

# Format and check code
lint:
	@echo "Formatting and vetting backend..."
	@cd $(BACKEND_DIR) && gofmt -s -w . && go vet ./...

# Build backend binary
build: lint
	@echo "Building backend binary..."
	@mkdir -p $(BUILD_DIR)
	@cd $(BACKEND_DIR) && go build -o bin/$(BINARY_NAME) .

# Run backend server
run_b:
	@echo "Starting backend server..."
	@cd $(BACKEND_DIR) && go run .

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@cd $(BACKEND_DIR) && go clean -cache
