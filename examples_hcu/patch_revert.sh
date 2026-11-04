#!/bin/bash
# Revert every file a patch touches, so the patch can be applied cleanly again.
# usage: patch_revert.sh <patch-file>
set -euo pipefail
cd "$(dirname "$0")/.."                 # this script lives in examples_hcu/
ROOT=$(pwd -P)
GIT=(git -c "safe.directory=$ROOT" -c "safe.directory=$ROOT/3rdparty/Megatron-LM")

YELLOW=${YELLOW:-'\033[33m'}
RESET=${RESET:-'\033[0m'}

if [ $# -lt 1 ]; then
    echo -e "${YELLOW}usage: $0 <patch-file>${RESET}" >&2
    exit 1
fi
PATCH=$1

"${GIT[@]}" rev-parse --git-dir >/dev/null 2>&1 || {
    echo -e "${YELLOW}[Patch] ERROR: $ROOT is not a usable git repository for user $(id -un)${RESET}" >&2
    exit 1
}

# $1 = repository inside the superproject ("" for the superproject), $2 = path in it
revert_path() {
    local repo=${1:-.} rel=$2
    if "${GIT[@]}" -C "$repo" cat-file -e "HEAD:$rel" 2>/dev/null; then
        "${GIT[@]}" -C "$repo" checkout -- "$rel"
    else
        rm -rf "${1:+$1/}$rel"
    fi
}

while read -r _added _removed path; do
    [ -n "${path:-}" ] || continue
    case "$path" in
        3rdparty/Megatron-LM/*) revert_path 3rdparty/Megatron-LM "${path#3rdparty/Megatron-LM/}" ;;
        *)                      revert_path "" "$path" ;;
    esac
done < <("${GIT[@]}" apply --numstat "$PATCH")

echo -e "${YELLOW}[Patch] reverted: $PATCH${RESET}"