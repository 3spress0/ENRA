#!/usr/bin/env bash
set -Eeuo pipefail
readonly REPO_RAW="https://raw.githubusercontent.com/3spress0/ENRA/main"
readonly INSTALL_PATH="/usr/local/sbin/enra"
readonly UPDATE_PATH="/usr/local/sbin/enra-update"

die() {
    printf '[ENRA installer] ERROR: %s\n' "$*" >&2
    exit 1
}

[[ "$EUID" -eq 0 ]] || die "Run as root: curl -fsSL https://raw.githubusercontent.com/3spress0/ENRA/main/install.sh | sudo bash"

RUN_SETUP=true
case "${1:-}" in
    "") ;;
    --setup) ;;
    --install-only|--no-setup) RUN_SETUP=false ;;
    -h|--help)
        printf 'ENRA installer\n\n'
        printf 'Usage:\n'
        printf '  sudo ./install.sh                 Install and start guided setup\n'
        printf '  sudo ./install.sh --install-only  Install without running setup\n'
        exit 0
        ;;
    *) die "Unknown option: $1. Use --help for usage." ;;
esac

HAS_TTY=false
if [[ -t 0 ]]; then
    HAS_TTY=true
elif exec 9</dev/tty 2>/dev/null; then
    exec 9<&-
    HAS_TTY=true
fi

if [[ "$HAS_TTY" != "true" ]]; then
    RUN_SETUP=false
fi

SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
SCRIPT_DIR=""
if [[ -n "$SCRIPT_SOURCE" && -f "$SCRIPT_SOURCE" ]]; then
    SCRIPT_DIR="$(cd -- "$(dirname -- "$SCRIPT_SOURCE")" && pwd)"
fi

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

download() {
    local url="$1" destination="$2"
    if command -v curl >/dev/null 2>&1; then
        curl --fail --location --silent --show-error --proto '=https' --tlsv1.2 "$url" -o "$destination"
    elif command -v wget >/dev/null 2>&1; then
        wget --https-only --quiet "$url" --output-document="$destination"
    else
        die "Install curl or wget first."
    fi
}

if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/enra.sh" && -f "$SCRIPT_DIR/update.sh" ]]; then
    cp "$SCRIPT_DIR/enra.sh" "$TEMP_DIR/enra.sh"
    cp "$SCRIPT_DIR/update.sh" "$TEMP_DIR/update.sh"
else
    printf '[ENRA installer] Downloading ENRA from GitHub...\n'
    download "$REPO_RAW/enra.sh" "$TEMP_DIR/enra.sh"
    download "$REPO_RAW/update.sh" "$TEMP_DIR/update.sh"
fi

bash -n "$TEMP_DIR/enra.sh" || die "The ENRA script failed its Bash syntax check."
bash -n "$TEMP_DIR/update.sh" || die "The ENRA updater failed its Bash syntax check."

install -d -m 0755 /usr/local/sbin
install -m 0755 "$TEMP_DIR/enra.sh" "$INSTALL_PATH"
install -m 0755 "$TEMP_DIR/update.sh" "$UPDATE_PATH"

printf '[ENRA installer] Installed command: %s\n' "$INSTALL_PATH"
printf '[ENRA installer] Installed updater: %s\n' "$UPDATE_PATH"

if [[ -r /etc/enra/enra.conf ]]; then
    printf '[ENRA installer] Existing configuration found. Refreshing ENRA services...\n'
    "$INSTALL_PATH" refresh
elif [[ "$RUN_SETUP" == "true" ]]; then
    printf '\n[ENRA installer] Starting the guided first-time setup...\n'
    if [[ -r /dev/tty ]]; then
        "$INSTALL_PATH" setup </dev/tty
    else
        "$INSTALL_PATH" setup
    fi
else
    printf '[ENRA installer] Installation complete. Start setup with: sudo enra setup\n'
fi
