#!/usr/bin/env bash
# Build ZIP files for each Hands-on AI skill, ready to attach to a GitHub Release.
# Usage: ./scripts/build-skill-zips.sh
# Output: dist/<skill-name>.zip for each skill

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/plugins/handsonai/skills"
DIST_DIR="$REPO_ROOT/dist"

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

for skill_dir in "$SKILLS_DIR"/*/; do
  skill_name="$(basename "$skill_dir")"
  # Zip from the parent directory so the ZIP contains the folder (not loose files)
  (cd "$SKILLS_DIR" && zip -r "$DIST_DIR/${skill_name}.zip" "$skill_name")
  echo "  ✓ ${skill_name}.zip"
done

echo ""
echo "All ZIPs built in $DIST_DIR"
echo ""
echo "To create a release:"
echo "  gh release create vX.Y.Z dist/*.zip --title 'vX.Y.Z' --notes 'Release notes here'"
