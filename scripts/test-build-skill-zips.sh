#!/usr/bin/env bash
# Guards what build-skill-zips.sh publishes:
#   <skill>.zip        skill folder at the root — one archive per skill, for every platform
#   handsonai-plugin.zip  the whole plugin, both manifests at the root — Claude, ChatGPT,
#                         and Copilot Cowork plugin upload (Copilot accepts only .zip)
# Every SKILL.md frontmatter may use only the Agent Skills standard fields; Copilot Cowork
# rejects the whole package on any other key (e.g. Claude Code's user-invocable).
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
ARCHIVE="$DIST/handsonai-plugin.zip"
PLUGIN_LIST="$(unzip -Z1 "$ARCHIVE" 2>/dev/null)"
for manifest in .claude-plugin/plugin.json .codex-plugin/plugin.json; do
  if printf '%s\n' "$PLUGIN_LIST" | grep -qx "$manifest"; then
    ok "handsonai-plugin.zip has $manifest at root"
  else
    bad "handsonai-plugin.zip missing $manifest at root"
  fi
done
missing=0
for skill_dir in "$ROOT"/plugins/handsonai/skills/*/; do
  skill="$(basename "$skill_dir")"
  printf '%s\n' "$PLUGIN_LIST" | grep -qx "skills/$skill/SKILL.md" \
    || { bad "handsonai-plugin.zip missing skills/$skill/SKILL.md"; missing=1; }
done
[ "$missing" -eq 0 ] && ok "handsonai-plugin.zip carries every skill"
[ -e "$DIST/handsonai.plugin" ] && bad "handsonai.plugin should no longer be built (Copilot needs .zip)"
# Skills only: ChatGPT ignores agents and Copilot Cowork skips them with a warning, so the
# framework-agent ships through the marketplace install (and framework-agent.zip) instead.
if printf '%s\n' "$PLUGIN_LIST" | grep -q '^agents/'; then
  bad "handsonai-plugin.zip should not contain agents/ (skills only)"
else
  ok "handsonai-plugin.zip carries no agents (skills only)"
fi

# Platform registry: every skill whose SKILL.md carries the "Platform registry:" note must
# ship its own byte-identical copy in references/, in its skill ZIP and in the plugin archive.
# Copilot Cowork drops the top-level registries/ folder, so the plugin archive leaves it out.
REG="$ROOT/plugins/handsonai/registries/platform-registry.json"
for skill_dir in "$ROOT"/plugins/handsonai/skills/*/; do
  skill="$(basename "$skill_dir")"
  grep -q '^> \*\*Platform registry:\*\*' "$skill_dir/SKILL.md" || continue
  if unzip -p "$DIST/$skill.zip" "$skill/references/platform-registry.json" 2>/dev/null | cmp -s - "$REG"; then
    ok "$skill.zip carries references/platform-registry.json"
  else
    bad "$skill.zip missing or stale references/platform-registry.json"
  fi
  if unzip -p "$ARCHIVE" "skills/$skill/references/platform-registry.json" 2>/dev/null | cmp -s - "$REG"; then
    ok "handsonai-plugin.zip carries skills/$skill/references/platform-registry.json"
  else
    bad "handsonai-plugin.zip missing or stale skills/$skill/references/platform-registry.json"
  fi
done
if printf '%s\n' "$PLUGIN_LIST" | grep -q '^registries/'; then
  bad "handsonai-plugin.zip should not contain top-level registries/ (Copilot skips it)"
else
  ok "handsonai-plugin.zip has no top-level registries/"
fi

# Agent Skills standard: frontmatter keys limited to these five. Checked inside every
# archive that ships a SKILL.md, because that is what the platforms validate.
ALLOWED='^(name|description|license|metadata|compatibility)$'
for archive in "$DIST"/*.zip; do
  for entry in $(unzip -Z1 "$archive" | grep 'SKILL.md$'); do
    keys="$(unzip -p "$archive" "$entry" | awk 'NR==1&&/^---$/{fm=1;next} fm&&/^---$/{exit} fm&&/^[A-Za-z_-]+:/{sub(/:.*/,"");print}')"
    badkeys="$(printf '%s\n' "$keys" | grep -Ev "$ALLOWED" | tr '\n' ' ')"
    [ -n "${badkeys// /}" ] && bad "$(basename "$archive"):$entry has non-standard frontmatter: $badkeys"
  done
done
ok "frontmatter check ran over every archive"

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
