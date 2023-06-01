#!/usr/bin/env -S just --justfile
# Shebang above is not necessary, but it allows you to run this file directly

# Install pre-commit hooks
hooks:
    pre-commit install --hook-type pre-commit
    pre-commit install --hook-type commit-msg

# Build and serve docs locally
serve-docs:
    just _copy_api_dev
    docker run \
        --rm \
        --interactive \
        --tty \
        --volume $(pwd):/app:ro \
        --publish 8000:8000 \
        --pull=always \
        docker.io/library/python:latest \
            bash -c "cd /app && \
                pip install -r docs/requirements.txt && \
                mkdocs serve \
                    --dev-addr 0.0.0.0:8000 \
                    --livereload"

# Build docs for publishing (should be run in CI only)
build-docs VERSION:
    #!/usr/bin/env -S bash
    set -e

    # Check if run in CI (GitHub Actions)
    if [[ -z "${CI}" ]]; then
        echo "This script should only be run in CI"
        exit 1
    fi

    # First, install requirements for building docs
    pip install -r docs/requirements.txt

    version="{{VERSION}}"

    # Determine if this is a prerelease version
    if echo "${version}" | grep -E -- "-(alpha|beta|rc)\.[0-9]+" > /dev/null; then
        prerelease="true"
    else
        prerelease="false"
    fi

    # Remove the leading 'v' if present
    version="${version#v}"

    # Extract the MAJOR and MINOR components
    major="${version%%.*}"
    minor="${version#*.}"
    minor="${minor%%.*}"

    trimmed="${major}.${minor}"

    echo "Building docs for version ${trimmed}"
    echo "Prerelease: ${prerelease}"

    # Copy API to docs for generating OpenAPI documentation
    just _copy_api "${trimmed}"

    if git show-ref --quiet refs/heads/gh-pages ; then
        if [[ "${prerelease}" == "true" ]]; then
            mike deploy --push --update-aliases --rebase "${trimmed}"
        else
            mike deploy --push --update-aliases --rebase "${trimmed}" latest
        fi
    else
        mike deploy --push --update-aliases --rebase "${trimmed}" latest
        mike set-default --push latest
    fi

_copy_api VERSION:
    rm -rf "docs/api-spec/{{VERSION}}"
    mkdir -p "docs/api-spec/{{VERSION}}"
    cp -r api/* "docs/api-spec/{{VERSION}}/"

_copy_api_dev:
    rm -rf "docs/api-spec/dev"
    mkdir -p "docs/api-spec/dev"
    cp -r api/* "docs/api-spec/dev/"
