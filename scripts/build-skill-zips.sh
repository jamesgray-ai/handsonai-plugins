#!/usr/bin/env bash
# Build ZIP files for each Hands-on AI skill and agent, ready to attach to a GitHub Release.
# Usage: ./scripts/build-skill-zips.sh
# Output: dist/<skill-name>.zip       — skill folder at the ZIP root (analyze/SKILL.md).
#                                       What claude.ai's "Upload a skill" requires.
#                                       Gemini Enterprise accepts it too. (The -flat.zip
#                                       layout was dropped 2026-10-05: no platform needed it.)
#         dist/<agent-name>.zip       — each agent's single .md file
#         dist/handsonai.plugin       — the whole plugin, uploadable in Claude and ChatGPT

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/plugins/handsonai/skills"
AGENTS_DIR="$REPO_ROOT/plugins/handsonai/agents"
DIST_DIR="$REPO_ROOT/dist"

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Every framework skill's dispatch blockquote defers to the shared write-rules
# contract at indexing-registry/references/registry-bundle.md. A standalone skill
# ZIP (claude.ai / ChatGPT upload) has no indexing-registry package, so without a
# bundled copy the model improvises registry writes — the exact drift the contract
# exists to prevent. Bundle the contract into every skill ZIP that references it,
# under the skill's own references/, at build time only (the canonical file stays
# single-source in indexing-registry; this stays out of the repo tree).
CONTRACT="$SKILLS_DIR/indexing-registry/references/registry-bundle.md"
[ -f "$CONTRACT" ] || { echo "ERROR: missing contract file $CONTRACT" >&2; exit 1; }

echo "Building skill ZIPs..."
for skill_dir in "$SKILLS_DIR"/*/; do
  skill_name="$(basename "$skill_dir")"
  # Zip from the parent directory so the ZIP contains the folder (not loose files)
  (cd "$SKILLS_DIR" && zip -r "$DIST_DIR/${skill_name}.zip" "$skill_name")
  # Bundle the shared contract into any skill that references it but doesn't ship it
  if [ "$skill_name" != "indexing-registry" ] \
     && grep -rq "registry-bundle.md" "$skill_dir" \
     && [ ! -f "${skill_dir}references/registry-bundle.md" ]; then
    staging="$(mktemp -d)"
    mkdir -p "$staging/$skill_name/references"
    cp "$CONTRACT" "$staging/$skill_name/references/registry-bundle.md"
    (cd "$staging" && zip "$DIST_DIR/${skill_name}.zip" "$skill_name/references/registry-bundle.md")
    rm -rf "$staging"
    echo "    + bundled references/registry-bundle.md"
  fi
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
echo "Building plugin archive..."
# The whole handsonai plugin as one uploadable archive, manifests at the archive root:
# .claude-plugin/plugin.json (Claude: Customize → Plugins → + → Upload) and
# .codex-plugin/plugin.json (ChatGPT: Customize → Plugins → Add → Upload plugin archive).
# For students whose plan or org can't add a marketplace but can upload a plugin.
PLUGIN_DIR="$REPO_ROOT/plugins/handsonai"
for manifest in .claude-plugin/plugin.json .codex-plugin/plugin.json; do
  [ -f "$PLUGIN_DIR/$manifest" ] || { echo "ERROR: missing $manifest in $PLUGIN_DIR" >&2; exit 1; }
done
(cd "$PLUGIN_DIR" && zip -qr "$DIST_DIR/handsonai.plugin" . -x '*.DS_Store')
echo "  ✓ handsonai.plugin"

echo ""
echo "All ZIPs built in $DIST_DIR"
echo ""
echo "To create a release:"
echo "  gh release create vX.Y.Z dist/*.zip dist/*.plugin --title 'vX.Y.Z' --notes 'Release notes here'"
