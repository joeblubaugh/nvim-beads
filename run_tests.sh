#!/bin/bash
# Test runner script for nvim-beads
# Runs busted tests with proper configuration

set -e

echo "Running nvim-beads test suite..."
echo "=================================="
echo ""

# Run tests with proper Lua path
busted tests/ --lpath './lua/?.lua;./lua/?/init.lua' --verbose

echo ""
echo "Test run complete!"
