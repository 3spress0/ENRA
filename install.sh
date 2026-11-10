#!/usr/bin/env bash
set -Eeuo pipefail

readonly REPO_RAW="https://raw.githubusercontent.com/3spress0/ENRA/main"
readonly INSTALL_PATH="/usr/local/sbin/enra"
readonly UPDATE_PATH="/usr/local/sbin/enra-update"

die() {
    printf '[ENRA installer] ERROR: %s\n' "$*" >&2
    exit 1
}

[[ "$EUID" -eq 0 ]] || die "Run as root: sudo ./install.sh"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
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

if [[ -n "${BASH_SOURCE[0]:-}" && -f "$SCRIPT_DIR/enra.sh" && -f "$SCRIPT_DIR/update.sh" ]]; then
    cp "$SCRIPT_DIR/enra.sh" "$TEMP_DIR/enra.sh"
    cp "$SCRIPT_DIR/update.sh" "$TEMP_DIR/update.sh"
else
    printf '[ENRA installer] Downloading ENRA from GitHub...\n'
    download "$REPO_RAW/enra.sh" "$TEMP_DIR/enra.sh"
    download "$REPO_RAW/update.sh" "$TEMP_DIR/update.sh"
fi

bash -n "$TEMP_DIR/enra.sh" || die "The downloaded enra.sh failed its Bash syntax check."
bash -n "$TEMP_DIR/update.sh" || die "The downloaded update.sh failed its Bash syntax check."

install -D -m 0755 "$TEMP_DIR/enra.sh" "$INSTALL_PATH"
install -D -m 0755 "$TEMP_DIR/update.sh" "$UPDATE_PATH"

printf '[ENRA installer] Installed command: %s\n' "$INSTALL_PATH"
printf '[ENRA installer] Installed updater: %s\n' "$UPDATE_PATH"

if [[ -r /etc/enra/enra.conf ]]; then
    printf '[ENRA installer] Existing configuration found. Refreshing systemd services...\n'
    "$INSTALL_PATH" refresh
else
    printf '[ENRA installer] Installation complete. Configure ENRA with: sudo enra setup\n'
fi
