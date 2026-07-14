#!/usr/bin/env bash
# snapshot.sh — build the triplydb Docker image, extract all verb/subcommand
# help texts, diff them against committed snapshots in snapshots/, and report
# any changes.
#
# Usage:
#   scripts/snapshot.sh [--update]
#
#   --update   Overwrite the committed snapshots with the current output.
#              Use this to record a new baseline after a deliberate CLI update.
#
# Exit codes:
#   0  No changes detected
#   1  One or more snapshots differ from the committed baseline

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SNAPSHOT_DIR="$REPO_ROOT/snapshots"
IMAGE="triplydb-cli-snapshot-test"
UPDATE=false

for arg in "$@"; do
  case "$arg" in
    --update) UPDATE=true ;;
    *) echo "Unknown argument: $arg" >&2; exit 1 ;;
  esac
done

# ---------------------------------------------------------------------------
# 1. Build the image so we always test the latest downloaded binary
# ---------------------------------------------------------------------------
echo "==> Building Docker image..."
docker build -q -t "$IMAGE" "$REPO_ROOT"

# ---------------------------------------------------------------------------
# 2. Run --help and extract the list of subcommand verbs
# ---------------------------------------------------------------------------
# The Triply CLI lists subcommands as lines indented with spaces followed by
# the command name and a description, e.g.:
#   Commands:
#     import-from-file  Import RDF files …
#     upload-asset      Upload binary assets …
# We extract the first word on each such line.
echo "==> Extracting verb list..."
RAW_HELP=$(docker run --rm "$IMAGE" --help 2>&1 | tr -d '\r' || true)
VERBS=$(echo "$RAW_HELP" \
  | awk '/^[[:space:]]+[a-z]/ && !/^[[:space:]]+-/ { print $1 }' \
  | grep -v '^help$' \
  | sort)

if [ -z "$VERBS" ]; then
  echo "ERROR: No subcommands found in --help output. Raw output:" >&2
  echo "$RAW_HELP" >&2
  exit 1
fi

mkdir -p "$SNAPSHOT_DIR"

# ---------------------------------------------------------------------------
# 3. If --update: write fresh snapshots and exit
# ---------------------------------------------------------------------------
if [ "$UPDATE" = true ]; then
  echo "==> Writing updated snapshots..."
  printf '%s\n' "$VERBS" > "$SNAPSHOT_DIR/verbs.txt"
  echo "  wrote snapshots/verbs.txt"
  while IFS= read -r verb; do
    docker run --rm "$IMAGE" "$verb" --help 2>&1 | tr -d '\r' \
      > "$SNAPSHOT_DIR/${verb}.txt" || true
    echo "  wrote snapshots/${verb}.txt"
  done <<< "$VERBS"
  echo "==> Done. Commit the updated files in snapshots/ to record the new baseline."
  exit 0
fi

# ---------------------------------------------------------------------------
# 4. Diff mode: compare against committed snapshots
# ---------------------------------------------------------------------------
CHANGED=false
DIFF_OUTPUT=""

# 4a. Verb list
VERBS_SNAPSHOT="$SNAPSHOT_DIR/verbs.txt"
if [ ! -f "$VERBS_SNAPSHOT" ]; then
  echo "WARNING: $VERBS_SNAPSHOT does not exist. Run with --update to create an initial baseline."
  CHANGED=true
  DIFF_OUTPUT+=$'\n'"### snapshots/verbs.txt (new — no baseline)"$'\n'
  DIFF_OUTPUT+="$VERBS"$'\n'
else
  VERBS_DIFF=$(diff --label "snapshots/verbs.txt (baseline)" \
                    --label "snapshots/verbs.txt (current)" \
                    -u "$VERBS_SNAPSHOT" <(echo "$VERBS") || true)
  if [ -n "$VERBS_DIFF" ]; then
    CHANGED=true
    DIFF_OUTPUT+=$'\n'"### snapshots/verbs.txt"$'\n''```diff'$'\n'"$VERBS_DIFF"$'\n''```'$'\n'
  fi
fi

# 4b. Per-verb help
# Use the union of committed verbs and currently found verbs
KNOWN_VERBS=()
if [ -f "$VERBS_SNAPSHOT" ]; then
  while IFS= read -r v; do KNOWN_VERBS+=("${v%$'\r'}"); done < "$VERBS_SNAPSHOT"
fi
while IFS= read -r v; do
  if [[ ! " ${KNOWN_VERBS[*]} " =~ " ${v} " ]]; then
    KNOWN_VERBS+=("$v")
  fi
done <<< "$VERBS"

for verb in "${KNOWN_VERBS[@]}"; do
  VERB_SNAPSHOT="$SNAPSHOT_DIR/${verb}.txt"
  CURRENT_HELP=$(docker run --rm "$IMAGE" "$verb" --help 2>&1 | tr -d '\r' || true)

  if [ ! -f "$VERB_SNAPSHOT" ]; then
    CHANGED=true
    DIFF_OUTPUT+=$'\n'"### snapshots/${verb}.txt (new verb — no baseline)"$'\n''```'$'\n'"$CURRENT_HELP"$'\n''```'$'\n'
  else
    VERB_DIFF=$(diff --label "snapshots/${verb}.txt (baseline)" \
                     --label "snapshots/${verb}.txt (current)" \
                     -u "$VERB_SNAPSHOT" <(echo "$CURRENT_HELP") || true)
    if [ -n "$VERB_DIFF" ]; then
      CHANGED=true
      DIFF_OUTPUT+=$'\n'"### snapshots/${verb}.txt"$'\n''```diff'$'\n'"$VERB_DIFF"$'\n''```'$'\n'
    fi
  fi
done

# ---------------------------------------------------------------------------
# 5. Report
# ---------------------------------------------------------------------------
if [ "$CHANGED" = true ]; then
  echo "==> CHANGES DETECTED in triplydb CLI help output:"
  echo "$DIFF_OUTPUT"
  # Write diff to a temp file so the CI workflow can read it
  DIFF_FILE="$REPO_ROOT/snapshot-diff.md"
  {
    echo "## triplydb CLI help output changed"
    echo ""
    echo "The weekly snapshot check detected changes in the \`triplydb\` CLI help output."
    echo "Review the diff below and update the committed snapshots if the change is intentional:"
    echo ""
    echo "\`\`\`"
    echo "scripts/snapshot.sh --update"
    echo "git add snapshots/"
    echo "git commit -m 'chore: update triplydb CLI snapshots'"
    echo "\`\`\`"
    echo ""
    echo "$DIFF_OUTPUT"
  } > "$DIFF_FILE"
  echo "(Full diff written to snapshot-diff.md)"
  exit 1
else
  echo "==> No changes detected. Snapshots are up to date."
  exit 0
fi
