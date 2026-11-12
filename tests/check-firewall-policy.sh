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

reject_rule() {
    local description="$1" pattern="$2"
    if grep -Fq -- "$pattern" "$ENRA_SCRIPT"; then
        printf '[FAIL] %s\n' "$description" >&2
        exit 1
    else
        printf '[PASS] %s\n' "$description"
    fi
}

require_rule "Per-interface IPv4 source validation exists" 'ip saddr != '
require_rule "Segment-to-uplink forwarding is IPv4-only" 'iifname { $segment_if_set } oifname "$UPLINK_IF" meta nfproto ipv4 accept'
require_rule "Inter-segment forwarding is explicitly IPv4-only" 'inter_segment_rule="iifname { $segment_if_set } oifname { $segment_if_set } meta nfproto ipv4 accept"'
require_rule "Upstream return traffic requires reply direction" 'ct state { established, related } ct direction reply accept'
require_rule "Forwarding from untrusted interfaces into segments is dropped" 'oifname { $segment_if_set } drop'
require_rule "Forwarding from segments to unauthorized interfaces is dropped" 'iifname { $segment_if_set } drop'
reject_rule "No broad established-traffic accept bypasses segment isolation" 'ct state established,related accept'
require_rule "Older configurations default inter-segment routing to disabled" 'ALLOW_INTER_SEGMENT_TRAFFIC="${ALLOW_INTER_SEGMENT_TRAFFIC:-false}"'
require_rule "Disable, enable and uninstall commands are exposed" 'uninstall) uninstall ;;'
require_rule "Validator inspects the active forwarding chain" 'nft list chain inet enra forward'
require_rule "Hotplug does not restart a stopped network service" 'if ! systemctl is-active --quiet enra-network.service; then'

hotplug_unit="$(sed -n '/Description=ENRA automatic network segment/,/\[Service\]/p' "$ENRA_SCRIPT")"
if grep -Fq 'Requires=' <<< "$hotplug_unit"; then
    printf '[FAIL] Hotplug unit must not force-start ENRA networking\n' >&2
    exit 1
fi
printf '[PASS] Hotplug unit does not force-start ENRA networking\n'

printf 'Firewall policy checks passed. Packet-level behaviour still requires integration testing.\n'
