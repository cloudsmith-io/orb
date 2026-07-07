#!/bin/bash
# Reads the installer result file, adds the CLI to PATH for subsequent steps,
# and writes optional API configuration to ~/.cloudsmith/config.ini.

if [ -z "${BASH_VERSION:-}" ]; then
  echo "install-cli requires bash; install it first (e.g. apk add bash)" >&2
  exit 1
fi
set -euo pipefail
: "${BASH_ENV:?BASH_ENV is required to persist PATH between steps}"
: "${CLOUDSMITH_CLI_OUTPUT_FILE:?CLOUDSMITH_CLI_OUTPUT_FILE must point at the installer result file}"

result_value() {
  awk -F= -v wanted="$1" '$1 == wanted { sub(/^[^=]*=/, ""); print; exit }' "$CLOUDSMITH_CLI_OUTPUT_FILE"
}

cli_version="$(result_value version)"
cli_target="$(result_value target)"
bin_dir="$(result_value bin_dir)"
executable="$(result_value executable)"
if [[ -z "$cli_version" || -z "$cli_target" || -z "$bin_dir" || -z "$executable" ]]; then
  echo "The installer did not report the expected installation results" >&2
  exit 1
fi

export PATH="$bin_dir:$PATH"
# shellcheck disable=SC2016  # $PATH must stay literal for later steps
printf 'export PATH=%q:$PATH\n' "$bin_dir" >> "$BASH_ENV"

if [[ -n "$PARAM_API_HOST" || -n "$PARAM_API_PROXY" || "$PARAM_API_SSL_VERIFY" == "false" || -n "$PARAM_API_USER_AGENT" ]]; then
  mkdir -p "$HOME/.cloudsmith"
  {
    echo "[default]"
    [[ -z "$PARAM_API_HOST" ]] || echo "api_host=$PARAM_API_HOST"
    [[ -z "$PARAM_API_PROXY" ]] || echo "api_proxy=$PARAM_API_PROXY"
    [[ "$PARAM_API_SSL_VERIFY" != "false" ]] || echo "api_ssl_verify=false"
    [[ -z "$PARAM_API_USER_AGENT" ]] || echo "api_user_agent=$PARAM_API_USER_AGENT"
  } > "$HOME/.cloudsmith/config.ini"
  echo "Cloudsmith CLI config written to $HOME/.cloudsmith/config.ini"
fi

echo "Cloudsmith CLI $cli_version installed for $cli_target"
"$executable" --version
