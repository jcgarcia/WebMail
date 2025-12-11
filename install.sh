#!/bin/bash
# Installation script for this application
# This is a template - customize for your specific needs

set -e

echo "Installing application..."

# Check for required tools
command -v node >/dev/null 2>&1 || { echo "Error: node is required but not installed."; exit 1; }
command -v pnpm >/dev/null 2>&1 || { echo "Error: pnpm is required but not installed."; exit 1; }

# Install dependencies
echo "Installing dependencies..."
pnpm install

# Build if needed
# pnpm build

echo "Installation complete!"
echo "Run 'pnpm dev' to start development"
