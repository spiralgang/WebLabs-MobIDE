name: Super-Coder-Lab

on:
  workflow_dispatch:
    inputs:
      model_repo:
        description: 'Hugging Face repo'
        default: 'Salesforce/codet5-small'
        required: true
      vendor_path:
        description: 'Path to vendor model into repo'
        default: 'app/src/main/assets/models/codet5-small'
        required: true
      target_branch:
        description: 'Branch to operate on'
        default: 'WebOps'
        required: true
      commit_mode:
        description: 'Commit directly or open PR'
        default: 'commit'
        required: true
        type: choice
        options:
          - pr
          - commit
      build_apk:
        description: 'Build APK after vendoring'
        default: 'true'
        required: true
        type: choice
        options:
          - 'true'
          - 'false'

permissions:
  contents: write
  pull-requests: write

jobs:
  setup:
    name: Setup Environment
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Install system dependencies
        run: |
          sudo apt-get update -y
          sudo apt-get install -y git-lfs jq
          git lfs install --system

  vendor:
    name: Vendor Model
    runs-on: ubuntu-latest
    needs: setup

    steps:
      - name: Vendor Hugging Face model
        run: git clone https://huggingface.co/Salesforce/codet5-small.git

      - name: Normalize .gitattributes for LFS
        run: |
          cat >> .gitattributes <<'EOF'
          *.bin filter=lfs diff=lfs merge=lfs -text
          *.safetensors filter=lfs diff=lfs merge=lfs -text
          *.pt filter=lfs diff=lfs merge=lfs -text
          *.onnx filter=lfs diff=lfs merge=lfs -text
          *.tflite filter=lfs diff=lfs merge=lfs -text
          EOF
          git add .gitattributes

      - name: Strip upstream git metadata from vendored model
        run: |
          find ${{ inputs.vendor_path }} -maxdepth 3 -type d -name ".git" -exec rm -rf {} +

      - name: Minimal model hygiene pass
        run: |
          find ${{ inputs.vendor_path }} -type d -name ".cache" -prune -exec rm -rf {} +
          find ${{ inputs.vendor_path }} -type f -exec chmod 0644 {} +

  commit:
    name: Commit Changes
    runs-on: ubuntu-latest
    needs: vendor

    steps:
      - name: Commit changes
        run: |
          git checkout -b fix/weblabs-codelab-${{ github.run_id }}
          git add ${{ inputs.vendor_path }}
          git commit -m "Vendor ${{ inputs.model_repo }} into ${{ inputs.vendor_path }} [LFS]"
          git push --set-upstream origin HEAD

      - name: Create Pull Request
        if: ${{ inputs.commit_mode == 'pr' }}
        uses: actions/github-script@v7
        with:
          script: |
            github.pulls.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: `Vendor ${core.getInput('model_repo')} into ${core.getInput('vendor_path')} [LFS]`,
              head: `fix/weblabs-codelab-${{ github.run_id }}`,
              base: core.getInput('target_branch'),
              body: 'Automated vendoring of models and configuration files.'
            })

      - name: Direct Commit
        if: ${{ inputs.commit_mode == 'commit' }}
        run: git merge HEAD

  build:
    name: Build APK
    runs-on: ubuntu-latest
    needs: commit
    if: ${{ inputs.build_apk == 'true' }}

    steps:
      - name: Set up JDK
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Grant execute permission to Gradle wrapper
        run: chmod +x ./gradlew

      - name: Build APK
        run: ./gradlew

      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: weblabs-mobide-apk
          path: build/outputs/apk/WebLabs-MobIDE*.apk
