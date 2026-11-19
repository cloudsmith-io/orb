#!/usr/bin/env bash
# Copyright 2026 Cloudsmith Ltd
# Halts the CircleCI job when CLOUDSMITH_API_KEY is not set.
set -euo pipefail

if [[ -z "${CLOUDSMITH_API_KEY:-}" ]]; then
  echo "CLOUDSMITH_API_KEY is not set; skipping the API key test."
  circleci-agent step halt
fi
