#!/usr/bin/env bash
set -Eeuo pipefail

readonly REPO_RAW="https://raw.githubusercontent.com/3spress0/ENRA/main"
readonly INSTALL_PATH="/usr/local/sbin/enra"
readonly UPDATE_PATH="/usr/local/sbin/enra-update"

die() {
    printf '[ENRA updater] ERROR: %s\n' "$*" >&2
    exit 1
}

[[ "$EUID" -eq 0 ]] || die "Run as root: sudo enra update"

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

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

printf '[ENRA updater] Checking GitHub: %s\n' "$REPO_RAW"
download "$REPO_RAW/enra.sh" "$TEMP_DIR/enra.sh"
download "$REPO_RAW/update.sh" "$TEMP_DIR/update.sh"

bash -n "$TEMP_DIR/enra.sh" || die "The downloaded enra.sh failed its Bash syntax check."
bash -n "$TEMP_DIR/update.sh" || die "The downloaded update.sh failed its Bash syntax check."

install -d -m 0755 /usr/local/sbin
ENRA_TEMP="$(mktemp "$INSTALL_PATH.XXXXXX")"
UPDATE_TEMP="$(mktemp "$UPDATE_PATH.XXXXXX")"
trap 'rm -rf "$TEMP_DIR"; rm -f "${ENRA_TEMP:-}" "${UPDATE_TEMP:-}"' EXIT

install -m 0755 "$TEMP_DIR/enra.sh" "$ENRA_TEMP"
install -m 0755 "$TEMP_DIR/update.sh" "$UPDATE_TEMP"
mv -f "$ENRA_TEMP" "$INSTALL_PATH"
mv -f "$UPDATE_TEMP" "$UPDATE_PATH"

printf '[ENRA updater] Installed the latest ENRA files.\n'
if [[ -r /etc/enra/enra.conf ]]; then
    "$INSTALL_PATH" refresh
else
    printf '[ENRA updater] ENRA is not configured yet. Run: sudo enra setup\n'
fi
