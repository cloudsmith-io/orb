#!/usr/bin/env bash
# Copyright 2026 Cloudsmith Ltd
# Pushes the tag for the newest version in CHANGELOG.md, and creates its GitHub
# release, when either one does not exist yet. For example, CHANGELOG.md starts
# with 3.1.0 and no v3.1.0 tag exists: the script pushes v3.1.0 at GITHUB_SHA,
# and CircleCI publishes orb 3.1.0 from that tag.
# Usage: GH_TOKEN=... GITHUB_SHA=... scripts/release.sh
set -euo pipefail

version="$(sed -n 's/^## \[\([0-9]*\.[0-9]*\.[0-9]*\)\].*/\1/p' CHANGELOG.md | head -n 1)"
[[ -n "$version" ]] || { echo "no released version in CHANGELOG.md" >&2; exit 1; }
tag="v$version"
status=0
git ls-remote --exit-code --tags origin "refs/tags/$tag" > /dev/null || status=$?
# CircleCI starts tag pipelines from push webhooks, so push the tag with git
# instead of creating it through the release API.
case "$status" in
  0) echo "$tag already exists" ;;
  2)
    git tag "$tag" "$GITHUB_SHA"
    git push origin "refs/tags/$tag"
    ;;
  *) exit "$status" ;;
esac
gh release view "$tag" > /dev/null 2>&1 \
  || gh release create "$tag" --verify-tag --title "$tag" --generate-notes
