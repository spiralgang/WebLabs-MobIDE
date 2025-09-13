- script: |
    mkdir -p /azp/_work/_tool
    ln -s /azp/_work/_tool /opt/hostedtoolcache
  displayName: "Symlink Python Tools Directory to Agent Tools Directory"
- task: UsePythonVersion@0
  displayName: "install Python 3.11"
  inputs:
    versionSpec: 3.11
