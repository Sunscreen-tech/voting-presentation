#!/usr/bin/env bash
# Shared utilities for shell scripts
# Provides logging, dependency checking, and repository validation

# Only use colors if outputting to a terminal
if [[ -t 1 ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[0;33m'
    readonly RESET='\033[0m'
else
    readonly RED=''
    readonly GREEN=''
    readonly YELLOW=''
    readonly RESET=''
fi

timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

log() {
    echo "$(timestamp) $*"
}

log_error() {
    echo -e "${RED}$(timestamp) ERROR: $*${RESET}" >&2
}

log_warning() {
    echo -e "${YELLOW}$(timestamp) WARNING: $*${RESET}" >&2
}

log_success() {
    echo -e "${GREEN}$(timestamp) $*${RESET}"
}

# Check for required commands and exit if any are missing
check_dependencies() {
    local missing=()
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing[*]}"
        log_error "Please install them or run in nix develop environment."
        exit 1
    fi
}

# Get repository root directory with validation
get_repo_root() {
    local repo_root
    if ! repo_root=$(git rev-parse --show-toplevel 2>&1); then
        log_error "Not in a git repository"
        log_error "This script must be run from within the repository"
        exit 1
    fi
    echo "$repo_root"
}
