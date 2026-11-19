#!/usr/bin/env bash
set -euo pipefail

bump_script="$(cd "$(dirname "$0")" && pwd)/bump-cli-version.sh"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT
today="$(date -u +%Y-%m-%d)"

mkdir -p "$test_root/src/commands"
cat > "$test_root/src/commands/install-cli.yml" <<'EOF'
parameters:
  cli-version:
    type: string
    default: "1.27.0"
  install-path:
    type: string
    default: ""
EOF

cat > "$test_root/CHANGELOG.md" <<'EOF'
# Changelog

## [Unreleased]

### Changed

- An unreleased change.

## [3.2.0] - 2026-10-01

### Fixed

- An earlier fix.
EOF

cat > "$test_root/expected-CHANGELOG.md" <<EOF
# Changelog

## [Unreleased]

## [3.3.0] - $today

### Changed

- Pin the default \`cli-version\` to Cloudsmith CLI 1.28.0.
- An unreleased change.

## [3.2.0] - 2026-10-01

### Fixed

- An earlier fix.
EOF

sed 's/default: "1.27.0"/default: "1.28.0"/' "$test_root/src/commands/install-cli.yml" > "$test_root/expected-install-cli.yml"

cd "$test_root"

# Unreleased changes make the CLI bump a minor release that includes them.
test "$(bash "$bump_script" 1.28.0)" = "3.3.0"
diff -u expected-install-cli.yml src/commands/install-cli.yml
diff -u expected-CHANGELOG.md CHANGELOG.md

# With no unreleased changes, the CLI bump is a patch release.
cat > expected-CHANGELOG.md <<EOF
# Changelog

## [Unreleased]

## [3.3.1] - $today

### Changed

- Pin the default \`cli-version\` to Cloudsmith CLI 1.29.0.

EOF
sed -n '/^## \[3\.3\.0\]/,$p' CHANGELOG.md >> expected-CHANGELOG.md
test "$(bash "$bump_script" 1.29.0)" = "3.3.1"
sed -i.bak 's/default: "1.28.0"/default: "1.29.0"/' expected-install-cli.yml
diff -u expected-install-cli.yml src/commands/install-cli.yml
diff -u expected-CHANGELOG.md CHANGELOG.md

# A version older than the pinned version changes nothing.
test -z "$(bash "$bump_script" 1.28.5 2> /dev/null)"
diff -u expected-install-cli.yml src/commands/install-cli.yml
diff -u expected-CHANGELOG.md CHANGELOG.md

# A different major version changes nothing.
test -z "$(bash "$bump_script" 2.0.0 2> /dev/null)"
diff -u expected-install-cli.yml src/commands/install-cli.yml
diff -u expected-CHANGELOG.md CHANGELOG.md

# A version that is not MAJOR.MINOR.PATCH is rejected.
if bash "$bump_script" latest 2> /dev/null; then
  echo "expected 'latest' to be rejected" >&2
  exit 1
fi

echo "bump-cli-version tests passed"
