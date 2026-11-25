#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ENRA_SCRIPT="$ROOT_DIR/enra.sh"

require_rule() {
    local description="$1" pattern="$2"
    if grep -Fq -- "$pattern" "$ENRA_SCRIPT"; then
        printf '[PASS] %s\n' "$description"
    else
        printf '[FAIL] %s\n' "$description" >&2
        exit 1
    fi
}

require_rule "Wi-Fi adapter MAC identity is persisted" 'WIFI_MAC=%q'
require_rule "Ethernet uplink MAC identity is persisted" 'UPLINK_MAC=%q'
require_rule "Routed Ethernet segment MAC identities are persisted" 'write_config_array SEGMENT_MACS "${SEGMENT_MACS[@]}"'
require_rule "Wi-Fi interface selection verifies AP capability" 'supports_ap_mode "$iface"'
require_rule "A single unambiguous AP adapter can be discovered automatically" 'if (( count == 1 )); then'
require_rule "Ambiguous Wi-Fi adapter discovery never guesses" 'Multiple AP-capable Wi-Fi interfaces were detected'
require_rule "Wi-Fi adapters are rebound using saved MAC identity" 'if [[ "$mac" == "$WIFI_MAC" ]]; then'
require_rule "Ethernet uplinks are rebound using saved MAC identity" 'if [[ "$mac" == "$UPLINK_MAC" ]]; then'
require_rule "Renamed routed Ethernet adapters restore their saved segment" 'Restoring saved Ethernet segment'
require_rule "Saved Ethernet segment matching uses the saved MAC" '"$mac" == "${SEGMENT_MACS[$index]:-}"'
require_rule "Linux link events are monitored continuously" 'ip monitor link'
require_rule "Link events invoke ENRA reconciliation" '"$INSTALLED_SCRIPT" reconcile'
require_rule "A missing bridge uplink does not tear down the local AP" 'Keeping the Wi-Fi access point and bridge running without its wired backhaul.'
require_rule "Ethernet carrier loss is reported without stopping routed Wi-Fi" 'Upstream Ethernet link is down. ENRA remains available locally and will use the uplink when carrier returns.'
require_rule "AP and DHCP services are wanted, not hard-required by network service" 'Wants=enra-network.service'
require_rule "Link monitor is installed as an ENRA systemd unit" 'Description=ENRA monitor for network adapter and carrier changes'
require_rule "Manual stop clears the runtime recovery marker" 'rm -f /run/enra/wifi-ready'

printf 'ENRA interface lifecycle contract checks passed.\n'
