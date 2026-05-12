.PHONY: all list help clean format lint test build_runner run_dev run_prod

# Default target: lists available commands
all: help

## help: Show this help message
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

## clean: Clean the project and fetch dependencies
clean: ## Clean the project and fetch dependencies
	@echo "Cleaning project..."
	@flutter clean
	@flutter pub get

## format: Format the code
format: ## Format the code
	@echo "Formatting code..."
	@dart format .

## lint: Analyze the code for issues
lint: ## Analyze the code for issues
	@echo "Analyzing code..."
	@flutter analyze

## test: Run all unit tests
test: ## Run all unit tests
	@echo "Running tests..."
	@flutter test

## build_runner: Run build_runner to generate code
build_runner: ## Run build_runner to generate code (e.g., for JSON serialization)
	@echo "Generating code..."
	@flutter pub run build_runner build --delete-conflicting-outputs

## fix: Automatically fix lint issues where possible
fix: ## Automatically fix lint issues
	@echo "Applying fixes..."
	@dart fix --apply

## check: Run format, lint, and test (Good for pre-commit)
check: format lint test ## Run format, lint, and test

## run_dev: Run the app in debug mode
run_dev: ## Run the app in debug mode
	@flutter run --debug

## run_prod: Run the app in release mode
run_prod: ## Run the app in release mode
	@flutter run --release
