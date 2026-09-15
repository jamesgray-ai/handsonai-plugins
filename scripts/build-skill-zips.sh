#!/usr/bin/env bash
# Build ZIP files for each Hands-on AI skill and agent, ready to attach to a GitHub Release.
# Usage: ./scripts/build-skill-zips.sh
# Output: dist/<skill-name>.zip       — skill folder at the ZIP root (analyze/SKILL.md).
#                                       What claude.ai's "Upload a skill" requires.
#         dist/<skill-name>-flat.zip  — SKILL.md at the ZIP root, references/ beside it.
#                                       What Gemini Enterprise documents ("SKILL.md in the
#                                       root directory") and what Copilot Cowork and
#                                       Gemini Spark describe. Same bytes, different
#                                       nesting; the platform decides which one loads.
#         dist/<agent-name>.zip       — each agent's single .md file

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
  # Flat variant: unpack the nested ZIP we just verified and re-zip from inside the
  # skill folder, so both archives always carry identical content (including the
  # bundled contract above) and can never drift from each other.
  flat_staging="$(mktemp -d)"
  unzip -q "$DIST_DIR/${skill_name}.zip" -d "$flat_staging"
  (cd "$flat_staging/$skill_name" && zip -qr "$DIST_DIR/${skill_name}-flat.zip" .)
  rm -rf "$flat_staging"
  echo "  ✓ ${skill_name}-flat.zip"
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
