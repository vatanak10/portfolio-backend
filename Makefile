include .envrc 

# Variables
MIGRATION_DIR=cmd/migrate/migrations
BINARY_NAME=main.exe
BUILD_DIR=bin
API_DIR=cmd/api
DOCKER_COMPOSE_FILE=docker-compose.yml

# Database connection string
DB_URL=postgres://admin:password@localhost:5432/portfolio?sslmode=disable

# Default target
.DEFAULT_GOAL := help

## help: Show this help message
.PHONY: help
help:
	@echo "Available commands:"
	@sed -n 's/^##//p' $(MAKEFILE_LIST) | column -t -s ':' | sed -e 's/^/ /'

## build: Build the application
.PHONY: build
build:
	@echo "Building application..."
	go build -o $(BUILD_DIR)/$(BINARY_NAME) ./$(API_DIR)

## run: Run the application
.PHONY: run
run:
	@echo "Running application..."
	go run ./$(API_DIR)/*.go

## dev: Run the application with hot reload using Air
.PHONY: dev
dev:
	@echo "Starting development server with Air..."
	air

## clean: Clean build artifacts
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)/*
	rm -rf tmp/*

## test: Run tests
.PHONY: test
test:
	@echo "Running tests..."
	go test -v ./...

## test-coverage: Run tests with coverage
.PHONY: test-coverage
test-coverage:
	@echo "Running tests with coverage..."
	go test -v -race -buildvcs -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

## lint: Run linter
.PHONY: lint
lint:
	@echo "Running linter..."
	golangci-lint run

## fmt: Format code
.PHONY: fmt
fmt:
	@echo "Formatting code..."
	go fmt ./...

## mod-tidy: Tidy up go modules
.PHONY: mod-tidy
mod-tidy:
	@echo "Tidying up go modules..."
	go mod tidy

## docker-up: Start database with Docker Compose
.PHONY: docker-up
docker-up:
	@echo "Starting database..."
	docker-compose -f $(DOCKER_COMPOSE_FILE) up -d

## docker-down: Stop database with Docker Compose
.PHONY: docker-down
docker-down:
	@echo "Stopping database..."
	docker-compose -f $(DOCKER_COMPOSE_FILE) down

## docker-logs: Show database logs
.PHONY: docker-logs
docker-logs:
	@echo "Showing database logs..."
	docker-compose -f $(DOCKER_COMPOSE_FILE) logs -f

## migration-create: Create a new migration file (usage: make migration-create name=migration_name)
.PHONY: migration-create
migration-create:
	@if [ -z "$(name)" ]; then \
		echo "Error: Please provide a migration name. Usage: make migration-create name=migration_name"; \
		exit 1; \
	fi
	@echo "Creating migration: $(name)"
	goose -dir $(MIGRATION_DIR) create $(name) sql

## migration-up: Run all pending migrations
.PHONY: migration-up
migration-up:
	@echo "Running migrations..."
	goose -dir $(MIGRATION_DIR) postgres "$(DB_URL)" up

## migration-down: Rollback the last migration
.PHONY: migration-down
migration-down:
	@echo "Rolling back last migration..."
	goose -dir $(MIGRATION_DIR) postgres "$(DB_URL)" down

## migration-status: Show migration status
.PHONY: migration-status
migration-status:
	@echo "Migration status:"
	goose -dir $(MIGRATION_DIR) postgres "$(DB_URL)" status

## migration-reset: Reset database (down all migrations then up)
.PHONY: migration-reset
migration-reset:
	@echo "Resetting database..."
	goose -dir $(MIGRATION_DIR) postgres "$(DB_URL)" reset

## setup: Setup development environment
.PHONY: setup
setup: docker-up migration-up
	@echo "Development environment setup complete!"

## install-tools: Install development tools
.PHONY: install-tools
install-tools:
	@echo "Installing development tools..."
	go install github.com/cosmtrek/air@latest
	go install github.com/pressly/goose/v3/cmd/goose@latest
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

## all: Run fmt, lint, test, and build
.PHONY: all
all: fmt lint test build
	@echo "All tasks completed successfully!"