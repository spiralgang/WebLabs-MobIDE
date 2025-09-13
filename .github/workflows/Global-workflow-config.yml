name: Global Continuation Workflow

on:
  workflow_call:

jobs:
  continue-on-error:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Run custom continuation script
        run: |
          #!/bin/bash
          set -e
          # Your custom continuation logic here
          # For example, capture errors and continue
          flake8 --format github --max-line-length=120 . || true
          # Add more linting tools or commands as needed
          # eslint . || true
          # pylint . || true
          echo "Continuing workflow despite errors..."
