#!/bin/bash
set -euo pipefail

INFO_PLIST="${1:?Usage: inject-build-metadata.sh <Info.plist>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_COMMIT="${CAPCAP_BUILD_COMMIT:-}"

if [ ! -f "$INFO_PLIST" ]; then
    echo "error: Info.plist not found at $INFO_PLIST" >&2
    exit 1
fi

if [ -z "$BUILD_COMMIT" ]; then
    BUILD_COMMIT="$(git -C "$ROOT" rev-parse --short=7 HEAD)"
fi

if [[ ! "$BUILD_COMMIT" =~ ^[0-9a-fA-F]{7,}$ ]]; then
    echo "error: invalid Git build commit: $BUILD_COMMIT" >&2
    exit 1
fi

if ! /usr/libexec/PlistBuddy -c "Set :CapcapGitCommit $BUILD_COMMIT" "$INFO_PLIST" 2>/dev/null; then
    /usr/libexec/PlistBuddy -c "Add :CapcapGitCommit string $BUILD_COMMIT" "$INFO_PLIST"
fi

echo "Injected Git build commit: $BUILD_COMMIT"

# ---------------------------------------------------------------
# Update source
# ---------------------------------------------------------------
# A build should only ever update itself from the repository it was built
# from. Upstream CI sets GITHUB_REPOSITORY, so every fork build automatically
# points at that fork; local builds fall back to the origin remote, then to the
# upstream project.
UPDATE_REPO="${CAPCAP_UPDATE_REPO:-${GITHUB_REPOSITORY:-}}"
if [ -z "$UPDATE_REPO" ]; then
    ORIGIN_URL="$(git -C "$ROOT" remote get-url origin 2>/dev/null || true)"
    case "$ORIGIN_URL" in
        *github.com[:/]*)
            UPDATE_REPO="${ORIGIN_URL#*github.com}"
            UPDATE_REPO="${UPDATE_REPO#:}"
            UPDATE_REPO="${UPDATE_REPO#/}"
            UPDATE_REPO="${UPDATE_REPO%.git}"
            ;;
    esac
fi
if [[ ! "$UPDATE_REPO" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]]; then
    UPDATE_REPO="realskyrin/capcap"
fi
if ! /usr/libexec/PlistBuddy -c "Set :CapcapUpdateRepo $UPDATE_REPO" "$INFO_PLIST" 2>/dev/null; then
    /usr/libexec/PlistBuddy -c "Add :CapcapUpdateRepo string $UPDATE_REPO" "$INFO_PLIST"
fi
echo "Injected update repository: $UPDATE_REPO"
