#!/bin/bash
set -e

# Function to run a command and continue on error
run_with_continuation() {
  "$@" || true
}

# Example usage
run_with_continuation flake8 --format github --max-line-length=3000 .
run_with_continuation eslint .
run_with_continuation pylint .
