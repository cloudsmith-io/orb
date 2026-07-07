#!/bin/bash
# Exports CLOUDSMITH_ORG and CLOUDSMITH_SERVICE_SLUG for subsequent steps.
# The Cloudsmith CLI exchanges the CircleCI OIDC token itself when the first
# authenticated command runs.

if [ -z "${BASH_VERSION:-}" ]; then
  echo "configure-oidc requires bash; install it first (e.g. apk add bash)" >&2
  exit 1
fi
set -euo pipefail
: "${BASH_ENV:?BASH_ENV is required to persist environment variables between steps}"

[[ -n "$PARAM_ORGANIZATION" ]] || { echo "organization must not be empty" >&2; exit 1; }
[[ -n "$PARAM_SERVICE_ACCOUNT" ]] || { echo "service-account must not be empty" >&2; exit 1; }

if [[ -z "${CIRCLE_OIDC_TOKEN_V2:-}" && -z "${CIRCLE_OIDC_TOKEN:-}" ]]; then
  echo "No CircleCI OIDC token is available (CIRCLE_OIDC_TOKEN_V2 / CIRCLE_OIDC_TOKEN)." >&2
  echo "CircleCI only issues OIDC tokens to jobs that use at least one context." >&2
  echo "Add a context to this job in your workflow configuration and re-run." >&2
  exit 1
fi

export CLOUDSMITH_ORG="$PARAM_ORGANIZATION"
export CLOUDSMITH_SERVICE_SLUG="$PARAM_SERVICE_ACCOUNT"
printf 'export CLOUDSMITH_ORG=%q\n' "$CLOUDSMITH_ORG" >> "$BASH_ENV"
printf 'export CLOUDSMITH_SERVICE_SLUG=%q\n' "$CLOUDSMITH_SERVICE_SLUG" >> "$BASH_ENV"

if [[ "$PARAM_VERIFY_AUTH" == "true" ]]; then
  if ! command -v cloudsmith > /dev/null 2>&1; then
    echo "verify-auth requires the Cloudsmith CLI; run install-cli before configure-oidc" >&2
    exit 1
  fi
  cloudsmith whoami
fi

echo "Cloudsmith OIDC configured for organization $CLOUDSMITH_ORG"
