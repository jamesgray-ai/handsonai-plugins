#!/usr/bin/env bash
# Guards what build-skill-zips.sh publishes:
#   <skill>.zip        skill folder at the root — one archive per skill, for every platform
#   handsonai.plugin   the whole plugin, both manifests at the root — Claude/ChatGPT plugin upload
# The -flat.zip layout was dropped 2026-10-05 (no platform needed it); this asserts it stays gone.
#
# Run: bash scripts/test-build-skill-zips.sh   (builds into a temp dir; leaves dist/ alone)

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok()  { echo "  ok    $1"; PASS=$((PASS + 1)); }
bad() { echo "  FAIL  $1"; FAIL=$((FAIL + 1)); }

# Build into a scratch copy so this never clobbers a dist/ you're about to release.
cp -R "$ROOT/plugins" "$ROOT/scripts" "$TMP/"
(cd "$TMP" && bash scripts/build-skill-zips.sh > "$TMP/build.log" 2>&1) || { echo "build failed:"; tail -5 "$TMP/build.log"; exit 1; }
DIST="$TMP/dist"

for skill_dir in "$ROOT"/plugins/handsonai/skills/*/; do
  skill="$(basename "$skill_dir")"
  nested="$DIST/$skill.zip"
  if [ ! -f "$nested" ]; then
    bad "$skill: $skill.zip must exist"; continue
  fi
  # Layout: the archive's first entry is the skill folder, not a loose SKILL.md.
  if unzip -Z1 "$nested" | grep -qx "$skill/SKILL.md" && ! unzip -Z1 "$nested" | grep -qx "SKILL.md"; then
    ok "$skill.zip has $skill/SKILL.md (folder at root)"
  else
    bad "$skill.zip layout wrong: $(unzip -Z1 "$nested" | head -3 | tr '\n' ' ')"
  fi
done

if ls "$DIST"/*-flat.zip > /dev/null 2>&1; then
  bad "no -flat.zip archives should be built: $(cd "$DIST" && ls *-flat.zip | head -3 | tr '\n' ' ')"
else
  ok "no -flat.zip archives built"
fi

# The contract bundling must survive into the archive of every skill that references it.
for skill_dir in "$ROOT"/plugins/handsonai/skills/*/; do
  skill="$(basename "$skill_dir")"
  [ "$skill" = "indexing-registry" ] && continue
  grep -rq "registry-bundle.md" "$skill_dir" || continue
  if unzip -Z1 "$DIST/$skill.zip" | grep -qx "$skill/references/registry-bundle.md"; then
    ok "$skill: registry-bundle.md bundled into $skill.zip"
  else
    bad "$skill: registry-bundle.md missing from $skill.zip"
  fi
done

# The plugin archive must carry both manifests at its root (Claude + ChatGPT upload)
# and every skill in the plugin.
PLUGIN_LIST="$(unzip -Z1 "$DIST/handsonai.plugin" 2>/dev/null)"
for manifest in .claude-plugin/plugin.json .codex-plugin/plugin.json; do
  if printf '%s\n' "$PLUGIN_LIST" | grep -qx "$manifest"; then
    ok "handsonai.plugin has $manifest at root"
  else
    bad "handsonai.plugin missing $manifest at root"
  fi
done
for skill_dir in "$ROOT"/plugins/handsonai/skills/*/; do
  skill="$(basename "$skill_dir")"
  printf '%s\n' "$PLUGIN_LIST" | grep -qx "skills/$skill/SKILL.md" \
    || bad "handsonai.plugin missing skills/$skill/SKILL.md"
done
ok "handsonai.plugin skill check ran"

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
