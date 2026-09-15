#!/usr/bin/env bash
# Guards the two ZIP layouts build-skill-zips.sh publishes for every skill:
#   <skill>.zip       skill folder at the root   — claude.ai upload
#   <skill>-flat.zip  SKILL.md at the root       — Gemini Enterprise / Cowork / Spark
# Both must unpack to identical content (the flat one is derived from the nested one),
# or a student on one platform silently gets a different skill than a student on another.
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
  nested="$DIST/$skill.zip" flat="$DIST/$skill-flat.zip"
  if [ ! -f "$nested" ] || [ ! -f "$flat" ]; then
    bad "$skill: both $skill.zip and $skill-flat.zip must exist"; continue
  fi
  # Layout: the nested archive's first entry is the skill folder; the flat one has SKILL.md at top level.
  if unzip -Z1 "$nested" | grep -qx "$skill/SKILL.md" && ! unzip -Z1 "$nested" | grep -qx "SKILL.md"; then
    ok "$skill.zip has $skill/SKILL.md (folder at root)"
  else
    bad "$skill.zip layout wrong: $(unzip -Z1 "$nested" | head -3 | tr '\n' ' ')"
  fi
  if unzip -Z1 "$flat" | grep -qx "SKILL.md" && ! unzip -Z1 "$flat" | grep -q "^$skill/"; then
    ok "$skill-flat.zip has SKILL.md at root"
  else
    bad "$skill-flat.zip layout wrong: $(unzip -Z1 "$flat" | head -3 | tr '\n' ' ')"
  fi
  # Content: byte-identical trees once the folder level is stripped.
  rm -rf "$TMP/a" "$TMP/b"; mkdir -p "$TMP/a" "$TMP/b"
  unzip -q "$nested" -d "$TMP/a"; unzip -q "$flat" -d "$TMP/b"
  if diff -r "$TMP/a/$skill" "$TMP/b" > /dev/null; then
    ok "$skill: nested and flat archives carry identical content"
  else
    bad "$skill: nested and flat archives differ: $(diff -rq "$TMP/a/$skill" "$TMP/b" | head -2 | tr '\n' ' ')"
  fi
done

# The contract bundling must survive into both archives for every skill that references it.
for skill_dir in "$ROOT"/plugins/handsonai/skills/*/; do
  skill="$(basename "$skill_dir")"
  [ "$skill" = "indexing-registry" ] && continue
  grep -rq "registry-bundle.md" "$skill_dir" || continue
  if unzip -Z1 "$DIST/$skill.zip" | grep -qx "$skill/references/registry-bundle.md" \
     && unzip -Z1 "$DIST/$skill-flat.zip" | grep -qx "references/registry-bundle.md"; then
    ok "$skill: registry-bundle.md bundled into both archives"
  else
    bad "$skill: registry-bundle.md missing from one of the archives"
  fi
done

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
