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
require_rule "$ENRA_SCRIPT" "Wi-Fi menu indexes are parsed as decimal" 'selection_number=$((10#$selection))'
require_rule "$ENRA_SCRIPT" "Ethernet segment counts are parsed as decimal" 'segment_count=$((10#$segment_count))'
require_rule "$ENRA_SCRIPT" "Bridge ports and extra segments only accept wired adapters" '[[ "$kind" == "Wired" ]] || continue'
require_rule "$ENRA_SCRIPT" "Routed upstream selection can use a separate Wi-Fi adapter" '[[ "$kind" == "Wired" || "$kind" == "Wi-Fi" ]] || continue'
require_rule "$ENRA_SCRIPT" "Interface choices include link state" 'interface_link_label "$iface"'
require_rule "$ENRA_SCRIPT" "Wi-Fi link state checks association" 'iw dev "$iface" link 2>/dev/null'
require_rule "$ENRA_SCRIPT" "Connected interfaces are preferred when no default route exists" 'elif (( connected_index > 0 )); then'
require_rule "$ENRA_SCRIPT" "Interface choices include current IPv4 address" 'interface_ipv4_label "$iface"'
require_rule "$ENRA_SCRIPT" "The computer default route is protected for bridge mode" 'In use; not selectable'
require_rule "$ENRA_SCRIPT" "Routed mode automatically chooses a free subnet when defaults overlap" 'The recommended Wi-Fi subnet is already in use.'
require_rule "$ENRA_SCRIPT" "Subnet fallback searches 172.16/12 and 192.168/16" 'range(16, 32)'
require_rule "$ENRA_SCRIPT" "Only Ethernet link-layer devices with a device path are classified as wired" 'cat "/sys/class/net/$iface/type"'
require_rule "$ENRA_SCRIPT" "Routed mode retains custom DNS resolver configuration" 'DNS server for connected devices [1.1.1.1]:'
require_rule "$ENRA_SCRIPT" "Custom DNS is validated before subnet fallback" 'IPv4 DNS server address, for example 1.1.1.1.'
require_rule "$ENRA_SCRIPT" "WPA2/WPA3 compatibility mode is the wizard default" 'Select security [3]: '
require_rule "$ENRA_SCRIPT" "Country detection skips unset global regulatory domains" 'candidate ~ /^[A-Z][A-Z]$/'
require_rule "$README_FILE" "README includes one-command installation" 'curl -fsSL https://raw.githubusercontent.com/3spress0/ENRA/main/install.sh | sudo bash'

printf 'ENRA first-run setup checks passed.\n'


# Exercise the subnet allocator against representative existing private routes.
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
mkdir -p "$tmp_dir/bin"

awk '
    /^next_segment_network\(\) \{/ { active = 1 }
    active && /python3 -/ { python = 1; next }
    python && /^PY$/ { exit }
    python { print }
' "$ENRA_SCRIPT" > "$tmp_dir/next_segment_network.py"

cat > "$tmp_dir/bin/ip" <<'EOF'
#!/usr/bin/env bash
case "$*" in
    "-4 route show table all") printf '%s\n' "${ENRA_TEST_ROUTES:-}" ;;
    "-4 -o address show scope global") printf '%s\n' "${ENRA_TEST_ADDRESSES:-}" ;;
    *) exit 1 ;;
esac
EOF
chmod +x "$tmp_dir/bin/ip"

result="$(ENRA_TEST_ROUTES='10.0.0.0/8 dev eth0 proto kernel scope link' PATH="$tmp_dir/bin:$PATH" python3 "$tmp_dir/next_segment_network.py")"
[[ "$result" == "172.16.0.0/24" ]] || {
    printf '[FAIL] Subnet allocator did not escape an occupied 10.0.0.0/8 range: %s\n' "$result" >&2
    exit 1
}
printf '[PASS] Subnet allocator falls back to 172.16/12 when 10/8 is occupied.\n'

result="$(ENRA_TEST_ROUTES=$'10.0.0.0/8 dev eth0 proto kernel scope link\n172.16.0.0/12 dev tun0 proto static' PATH="$tmp_dir/bin:$PATH" python3 "$tmp_dir/next_segment_network.py")"
[[ "$result" == "192.168.0.0/24" ]] || {
    printf '[FAIL] Subnet allocator did not use 192.168/16 when 10/8 and 172.16/12 are occupied: %s\n' "$result" >&2
    exit 1
}
printf '[PASS] Subnet allocator falls back to 192.168/16 when 10/8 and 172.16/12 are occupied.\n'

bash "$INSTALL_SCRIPT" --help >/dev/null
printf '[PASS] Installer help is available without root privileges.\n'
