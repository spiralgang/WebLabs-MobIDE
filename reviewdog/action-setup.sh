# Install the latest version. (Install it into ./bin/ by default).
$ curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s

# Specify installation directory ($(go env GOPATH)/bin/) and version.
$ curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s -- -b $(go env GOPATH)/bin [vX.Y.Z]

# In alpine linux (as it does not come with curl by default)
$ wget -O - -q https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s [vX.Y.Z]

steps:
- uses: reviewdog/action-setup@d8edfce3dd5e1ec6978745e801f9c50b5ef80252 # v1.4.0
  with:
    reviewdog_version: latest # Optional. [latest,nightly,v.X.Y.Z]

    $ npm install --save-dev eslint-formatter-rdjson
$ eslint -f rdjson . | reviewdog -f=rdjson -reporter=github-pr-review

$ gofmt -s -d . | reviewdog -name="gofmt" -f=diff -f.diff.strip=0 -reporter=github-pr-review
$ shellcheck -f diff $(shfmt -f .) | reviewdog -f=diff

{" runner:
  <tool-name>:
    cmd: <command> # (required)
    errorformat: # (optional if you use `format`)
      - <list of errorformat>
    format: <format-name> # (optional if you use `errorformat`. e.g. golint,rdjson,rdjsonl)
    name: <tool-name> # (optional. you can overwrite <tool-name> defined by runner key)
    level: <level> # (optional. same as -level flag. [info,warning,error])

  # examples
  golint:
    cmd: golint ./...
    errorformat:
      - "%f:%l:%c: %m"
    level: warning
  govet:
    cmd: go vet -all .
    format: govet
  your-awesome-linter:
    cmd: awesome-linter run
    format: rdjson
    name: AwesomeLinter "}

    $ reviewdog -diff="git diff FETCH_HEAD"
project/run_test.go:61:28: [golint] error strings should not end with punctuation
project/run.go:57:18: [errcheck]        defer os.Setenv(name, os.Getenv(name))
project/run.go:58:12: [errcheck]        os.Setenv(name, "")
# You can use -runners to run only specified runners.
$ reviewdog -diff="git diff FETCH_HEAD" -runners=golint,govet
project/run_test.go:61:28: [golint] error strings should not end with punctuation
# You can use -conf to specify config file path.
$ reviewdog -conf=./.reviewdog.yml -reporter=github-pr-check

{"- name: Run reviewdog
    env:
      REVIEWDOG_GITHUB_API_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    run: |
      golint ./... | reviewdog -f=golint -reporter=github-pr-check "}

$ golint ./... | reviewdog -f=golint -diff="git diff FETCH_HEAD"
