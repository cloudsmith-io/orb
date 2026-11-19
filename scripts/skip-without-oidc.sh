#!/usr/bin/env bash
# Copyright 2026 Cloudsmith Ltd
# Halts the CircleCI job unless the OIDC test is enabled and can get a token.
# Set TEST_ORGANIZATION and TEST_SERVICE_ACCOUNT from the pipeline parameters.
set -euo pipefail

if [[ "${CLOUDSMITH_OIDC_TEST:-}" != "true" ]]; then
  echo "CLOUDSMITH_OIDC_TEST is not 'true'; skipping the OIDC test."
  circleci-agent step halt
elif [[ -z "${TEST_ORGANIZATION:-}" || -z "${TEST_SERVICE_ACCOUNT:-}" ]]; then
  echo "test-organization/test-service-account pipeline parameters are not set; skipping the OIDC test."
  circleci-agent step halt
elif [[ -z "${CIRCLE_OIDC_TOKEN_V2:-}" && -z "${CIRCLE_OIDC_TOKEN:-}" ]]; then
  echo "No OIDC token; the job must use a context. Skipping the OIDC test."
  circleci-agent step halt
fi
