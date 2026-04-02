.PHONY: all build build-shared build-client build-server build-frontend test run run-quick dev clean format release

all: build

# Build all packages
build: build-shared build-client build-server

build-shared:
	@echo "Building shared package..."
	cd packages/shared && gleam build

build-client: build-shared
	@echo "Building client package..."
	cd packages/client && gleam build

build-server: build-shared
	@echo "Building server package..."
	cd packages/server && gleam build

# Build frontend bundle for production
build-frontend: build-client
	@echo "Building frontend bundle..."
	cd packages/client && gleam run -m lustre/dev build frontend/app --outdir=../server/priv/static/js

# Full release build
release: clean build-shared build-frontend build-server
	@echo "Release build complete!"

# Run tests for all packages
test:
	@echo "Testing shared package..."
	cd packages/shared && gleam test
	@echo "Testing client package..."
	cd packages/client && gleam test
	@echo "Testing server package..."
	cd packages/server && gleam test

# Run the server (requires build first)
run: build-frontend build-server
	@echo "Starting server..."
	cd packages/server && gleam run

# Quick run (skip frontend rebuild)
run-quick:
	cd packages/server && gleam build && gleam run

# Start Lustre dev server with hot reload
dev:
	@echo "Starting Lustre dev server..."
	cd packages/client && gleam run -m lustre/dev start

# Clean all build artifacts
clean:
	rm -rf packages/*/build
	rm -f packages/server/priv/static/js/app.js

# Format all code
format:
	cd packages/shared && gleam format src test
	cd packages/client && gleam format src test
	cd packages/server && gleam format src test
