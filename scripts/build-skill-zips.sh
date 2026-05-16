#!/usr/bin/env bash
# Build ZIP files for each Hands-on AI skill and agent, ready to attach to a GitHub Release.
# Usage: ./scripts/build-skill-zips.sh
# Output: dist/<skill-name>.zip for each skill, dist/<agent-name>.zip for each agent

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/plugins/handsonai/skills"
AGENTS_DIR="$REPO_ROOT/plugins/handsonai/agents"
DIST_DIR="$REPO_ROOT/dist"

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "Building skill ZIPs..."
for skill_dir in "$SKILLS_DIR"/*/; do
  skill_name="$(basename "$skill_dir")"
  # Zip from the parent directory so the ZIP contains the folder (not loose files)
  (cd "$SKILLS_DIR" && zip -r "$DIST_DIR/${skill_name}.zip" "$skill_name")
  echo "  ✓ ${skill_name}.zip"
done

echo ""
echo "Building agent ZIPs..."
for agent_file in "$AGENTS_DIR"/*.md; do
  [ -e "$agent_file" ] || continue
  agent_name="$(basename "$agent_file" .md)"
  # Each agent is a single .md file; zip it standalone (filename = <agent-name>.zip, content = <agent-name>.md)
  (cd "$AGENTS_DIR" && zip "$DIST_DIR/${agent_name}.zip" "${agent_name}.md")
  echo "  ✓ ${agent_name}.zip"
done

echo ""
echo "All ZIPs built in $DIST_DIR"
echo ""
echo "To create a release:"
echo "  gh release create vX.Y.Z dist/*.zip --title 'vX.Y.Z' --notes 'Release notes here'"
