.PHONY: test test-unit test-verbose test-coverage help

help:
	@echo "Available targets:"
	@echo "  make test              - Run all tests"
	@echo "  make test-verbose      - Run tests with verbose output"
	@echo "  make test-coverage     - Run tests with coverage report"
	@echo "  make help              - Show this help message"

test:
	busted tests/

test-verbose:
	busted tests/ --verbose

test-coverage:
	busted tests/ --coverage

test-unit:
	@echo "Running unit tests (excluding integration tests)..."
	busted tests/ --filter-not "requires actual Beads instance"
