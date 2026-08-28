#!/usr/bin/env bash
# codex_call.sh — one safe call to OpenAI Codex as a read-only critic.
#
# Usage:   codex_call.sh <prompt-file> [thread-id]
#   No thread-id  -> fresh session:   codex exec -s read-only …
#   With thread-id -> resumed session: codex exec resume <id> -c sandbox_mode="read-only" …
#
# Prints a small KEY=VALUE report (STATUS, THREAD_ID, REPLY_FILE, VERDICT, …) and, on
# failure, the stderr tail. Semantics, contracts, and the failure ladder are defined in
# ../references/codex-protocol.md — that document is authoritative; this script only
# automates its mechanics (mktemp scratch files, stdin feed, stream capture, thread-id
# parse, success contract, last-line verdict parse).
#
# Run it from the TARGET REPO ROOT (codex refuses untrusted, non-git directories).
set -uo pipefail

P="${1:?usage: codex_call.sh <prompt-file> [thread-id]}"
TID="${2:-}"
[ -s "$P" ] || { echo "STATUS=fail"; echo "ERROR=prompt file missing or empty: $P"; exit 2; }

command -v codex >/dev/null 2>&1 || { echo "STATUS=fail"; echo "CLASS=deterministic"; echo "ERROR=codex binary not found (install / PATH) — do not retry"; exit 127; }
CODEX_VERSION=$(codex --version 2>/dev/null | head -1)
REPLY=$(mktemp); STREAM=$(mktemp); ERR=$(mktemp)

if [ -z "$TID" ]; then
  codex exec -s read-only --json -o "$REPLY" - <"$P" >"$STREAM" 2>"$ERR"
else
  codex exec resume "$TID" -c sandbox_mode="read-only" --json -o "$REPLY" - <"$P" >"$STREAM" 2>"$ERR"
fi
RC=$?

NEW_TID=$(grep -o '"thread_id":"[^"]*"' "$STREAM" | head -1 | cut -d'"' -f4)
[ -n "$TID" ] && [ -z "$NEW_TID" ] && NEW_TID="$TID"

# Success contract (codex-protocol.md): fresh = non-empty reply + thread.started in stream;
# resume = non-empty fresh reply. stderr noise and stream "error" events are NOT failure.
OK=1
[ -s "$REPLY" ] || OK=0
if [ -z "$TID" ]; then
  grep -q '"type":"thread.started"' "$STREAM" || OK=0
fi

# Verdict parses from the LAST NON-EMPTY line of the reply (may lack a trailing newline);
# only the four contract values count. VERDICT_VALID=0 means: treat as MATERIAL + one
# retry-with-reminder per codex-protocol.md — never carry on as if it were CLEAN.
LAST_LINE=$(grep -v '^[[:space:]]*$' "$REPLY" 2>/dev/null | tail -n 1)
VERDICT=$(printf '%s\n' "$LAST_LINE" | grep -oE 'VERDICT:[[:space:]]*(BLOCKING|MATERIAL|MINOR|CLEAN)' | head -1 | sed 's/VERDICT:[[:space:]]*//')
if [ -n "$VERDICT" ]; then VERDICT_VALID=1; else VERDICT_VALID=0; fi

if [ "$OK" -eq 1 ]; then echo "STATUS=ok"; else echo "STATUS=fail"; fi
echo "EXIT_CODE=$RC"
echo "CODEX_VERSION=${CODEX_VERSION:-unknown}"
echo "THREAD_ID=${NEW_TID:-unknown}"
echo "REPLY_FILE=$REPLY"
echo "STREAM_FILE=$STREAM"
echo "ERR_FILE=$ERR"
echo "VERDICT=${VERDICT:-none}"
echo "VERDICT_VALID=$VERDICT_VALID"
if [ "$OK" -eq 0 ]; then
  echo "--- stderr tail (see codex-protocol.md failure ladder) ---"
  tail -n 8 "$ERR" 2>/dev/null
fi
[ "$OK" -eq 1 ] || exit 1
