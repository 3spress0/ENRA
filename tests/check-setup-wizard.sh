#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ENRA_SCRIPT="$ROOT_DIR/enra.sh"
INSTALL_SCRIPT="$ROOT_DIR/install.sh"
README_FILE="$ROOT_DIR/README.md"

require_rule() {
    local file="$1" description="$2" pattern="$3"
    if grep -Fq -- "$pattern" "$file"; then
        printf '[PASS] %s\n' "$description"
    else
        printf '[FAIL] %s\n' "$description" >&2
        exit 1
    fi
}

require_rule "$INSTALL_SCRIPT" "Installer can run setup automatically" '"$INSTALL_PATH" setup'
require_rule "$INSTALL_SCRIPT" "Installer supports install-only mode" '--install-only'
require_rule "$INSTALL_SCRIPT" "Installer checks for an actual controlling terminal" 'exec 9</dev/tty 2>/dev/null'
require_rule "$INSTALL_SCRIPT" "Piped installer reads prompts from the terminal" 'setup </dev/tty'
require_rule "$ENRA_SCRIPT" "Wi-Fi adapters are filtered by access-point support" 'mapfile -t choices < <(wireless_ap_interfaces)'
require_rule "$ENRA_SCRIPT" "Only wired adapters are selectable for Ethernet roles" '[[ "$kind" == "Wired" ]] || continue'
require_rule "$ENRA_SCRIPT" "Interface choices include link state" 'interface_link_label "$iface"'
require_rule "$ENRA_SCRIPT" "Interface choices include current IPv4 address" 'interface_ipv4_label "$iface"'
require_rule "$ENRA_SCRIPT" "The computer default route is protected for bridge mode" 'In use; not selectable'
require_rule "$ENRA_SCRIPT" "Routed mode automatically chooses a free subnet when defaults overlap" 'The recommended Wi-Fi subnet is already in use.'
require_rule "$ENRA_SCRIPT" "WPA2/WPA3 compatibility mode is the wizard default" 'Select security [3]: '
require_rule "$README_FILE" "README includes one-command installation" 'curl -fsSL https://raw.githubusercontent.com/3spress0/ENRA/main/install.sh | sudo bash'

printf 'ENRA first-run setup checks passed.\n'
