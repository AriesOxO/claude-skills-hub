#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT

export CLAUDE_SKILLS_DIR="$temp_dir/installed"

bash "$repo_root/install.sh" install \
  --local "$repo_root/skills/x-twitter-data" \
  x-twitter-data
test -f "$CLAUDE_SKILLS_DIR/x-twitter-data/SKILL.md"

mkdir -p "$temp_dir/invalid-skill"
if bash "$repo_root/install.sh" install \
  --local "$temp_dir/invalid-skill" \
  invalid-skill; then
  echo "Expected invalid local skill installation to fail." >&2
  exit 1
fi
