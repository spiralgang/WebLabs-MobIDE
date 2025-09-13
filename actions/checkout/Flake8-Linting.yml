name: Flake8 Linting

on:
  push:
    paths:
      - '**.py'
  pull_request:
    paths:
      - '**.py'

jobs:
  lint:
    name: Lint Python Files
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'

      - name: Install flake8
        run: pip install flake8

      - name: Run flake8 on all Python files
        run: flake8 --format github --max-line-length=120 .
        continue-on-error: true

      - name: Display flake8 results
        run: echo "Flake8 linting completed. Check the previous step for details."
