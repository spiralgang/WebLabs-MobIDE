name: Reusable Linting Workflow

on:
  workflow_call:
    inputs:
      max-line-length:
        description: 'Maximum line length for flake8'
        required: false
        default: '79'
      continue-on-error:
        description: 'Continue on error'
        required: false
        default: 'true'

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'

      - name: Install flake8
        run: pip install flake8

      - name: Run flake8 on all Python files
        run: flake8 --format github --max-line-length=${{ inputs.max-line-length }} .
        continue-on-error: ${{ inputs.continue-on-error }}

      - name: Run other linting tools
        run: |
          eslint . || true
          pylint . || true
        continue-on-error: ${{ inputs.continue-on-error }}
