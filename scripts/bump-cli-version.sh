#!/usr/bin/env bash
# Pins the default cli-version of install-cli to a new Cloudsmith CLI release
# and records the change as a release of the orb in CHANGELOG.md. The release
# is a patch release, or a minor release that also includes the entries under
# [Unreleased] when there are any.
# Prints the new orb version. Prints nothing when the orb already pins that
# version or a newer one, or when the release has a different major version.
# Usage: scripts/bump-cli-version.sh CLI_VERSION
set -euo pipefail

cli_version="${1:-}"
[[ "$cli_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] \
  || { echo "usage: $0 MAJOR.MINOR.PATCH" >&2; exit 1; }

command_file="src/commands/install-cli.yml"
pinned_version="$(awk '
  /^  cli-version:/ { in_cli_version = 1 }
  in_cli_version && /^    default:/ { gsub(/"/, "", $2); print $2; exit }
' "$command_file")"
[[ -n "$pinned_version" ]] || { echo "no cli-version default in $command_file" >&2; exit 1; }
newest_version="$(printf '%s\n' "$pinned_version" "$cli_version" | sort -V | tail -n 1)"
if [[ "$pinned_version" == "$newest_version" ]]; then
  echo "$command_file already pins Cloudsmith CLI $pinned_version" >&2
  exit 0
fi
if [[ "${cli_version%%.*}" != "${pinned_version%%.*}" ]]; then
  echo "Cloudsmith CLI $cli_version has a different major version than the pinned $pinned_version" >&2
  exit 0
fi

released_version="$(sed -n 's/^## \[\([0-9]*\.[0-9]*\.[0-9]*\)\].*/\1/p' CHANGELOG.md | head -n 1)"
[[ -n "$released_version" ]] || { echo "no released version in CHANGELOG.md" >&2; exit 1; }
unreleased_changes="$(awk '
  /^## \[/ { in_unreleased = ($0 == "## [Unreleased]"); next }
  in_unreleased && $0 != ""
' CHANGELOG.md)"
IFS=. read -r major minor patch <<< "$released_version"
if [[ -n "$unreleased_changes" ]]; then
  orb_version="$major.$(( minor + 1 )).0"
else
  orb_version="$major.$minor.$(( patch + 1 ))"
fi
has_changed_section=0
if grep -qFx '### Changed' <<< "$unreleased_changes"; then
  has_changed_section=1
fi

awk -v cli_version="$cli_version" '
  /^  cli-version:/ { in_cli_version = 1 }
  in_cli_version && /^    default:/ { sub(/".*"/, "\"" cli_version "\""); in_cli_version = 0 }
  { print }
' "$command_file" > "$command_file.new"
mv "$command_file.new" "$command_file"

awk -v orb_version="$orb_version" -v today="$(date -u +%Y-%m-%d)" \
  -v has_changed_section="$has_changed_section" \
  -v entry="- Pin the default \`cli-version\` to Cloudsmith CLI $cli_version." '
  { print }
  add_entry_after_blank && $0 == "" { print entry; add_entry_after_blank = 0 }
  $0 == "## [Unreleased]" {
    print ""
    print "## [" orb_version "] - " today
    in_unreleased = 1
    if (!has_changed_section) { print ""; print "### Changed"; print ""; print entry }
    next
  }
  /^## \[/ { in_unreleased = 0 }
  in_unreleased && $0 == "### Changed" { add_entry_after_blank = 1 }
' CHANGELOG.md > CHANGELOG.md.new
mv CHANGELOG.md.new CHANGELOG.md

echo "$orb_version"
