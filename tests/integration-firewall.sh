#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "$EUID" -ne 0 ]]; then
    printf 'Run this integration test as root.\n' >&2
    exit 1
fi

for command in ip nft ping sysctl; do
    command -v "$command" >/dev/null 2>&1 || {
        printf 'Missing test dependency: %s\n' "$command" >&2
        exit 1
    }
done

suffix="$$"
router="enra-fw-router-$suffix"
wifi="enra-fw-wifi-$suffix"
lan="enra-fw-lan-$suffix"
upstream="enra-fw-upstream-$suffix"
untrusted="enra-fw-untrusted-$suffix"
namespaces=("$router" "$wifi" "$lan" "$upstream" "$untrusted")

cleanup() {
    local namespace
    for namespace in "${namespaces[@]}"; do
        ip netns del "$namespace" >/dev/null 2>&1 || true
    done
}
trap cleanup EXIT

for namespace in "${namespaces[@]}"; do
    ip netns add "$namespace"
    ip -n "$namespace" link set lo up
done

create_link() {
    local router_if="$1" peer_if="$2" peer_ns="$3"
    ip link add "$router_if" type veth peer name "$peer_if"
    ip link set "$router_if" netns "$router"
    ip link set "$peer_if" netns "$peer_ns"
}

create_link r-wifi c-wifi "$wifi"
create_link r-lan c-lan "$lan"
create_link r-up u0 "$upstream"
create_link r-bad b0 "$untrusted"

ip -n "$router" address add 10.42.0.1/24 dev r-wifi
ip -n "$router" address add 10.43.0.1/24 dev r-lan
ip -n "$router" address add 192.0.2.1/24 dev r-up
ip -n "$router" address add 198.51.100.1/24 dev r-bad
ip -n "$wifi" address add 10.42.0.10/24 dev c-wifi
ip -n "$lan" address add 10.43.0.10/24 dev c-lan
ip -n "$upstream" address add 192.0.2.2/24 dev u0
ip -n "$untrusted" address add 198.51.100.2/24 dev b0

ip -n "$router" -6 address add fd42:42::1/64 dev r-wifi
ip -n "$router" -6 address add fd42:43::1/64 dev r-up
ip -n "$wifi" -6 address add fd42:42::10/64 dev c-wifi
ip -n "$upstream" -6 address add fd42:43::2/64 dev u0

for pair in "$router:r-wifi" "$router:r-lan" "$router:r-up" "$router:r-bad" \
            "$wifi:c-wifi" "$lan:c-lan" "$upstream:u0" "$untrusted:b0"; do
    namespace="${pair%%:*}"
    iface="${pair#*:}"
    ip -n "$namespace" link set "$iface" up
done

ip -n "$wifi" route add default via 10.42.0.1
ip -n "$lan" route add default via 10.43.0.1
ip -n "$upstream" route add default via 192.0.2.1
ip -n "$untrusted" route add default via 198.51.100.1
ip -n "$wifi" -6 route add default via fd42:42::1
ip -n "$upstream" -6 route add default via fd42:43::1

ip netns exec "$router" sysctl -q -w net.ipv4.ip_forward=1
ip netns exec "$router" sysctl -q -w net.ipv6.conf.all.forwarding=1

apply_firewall() {
    local inter_segment="$1" inter_rule=""
    if [[ "$inter_segment" == "true" ]]; then
        inter_rule='        iifname { "r-wifi", "r-lan" } oifname { "r-wifi", "r-lan" } meta nfproto ipv4 accept'
    fi

    ip netns exec "$router" nft flush ruleset
    ip netns exec "$router" nft -f - <<EOF
table inet enra {
    chain forward {
        type filter hook forward priority filter; policy accept;
        iifname "r-wifi" meta nfproto ipv4 ip saddr != 10.42.0.0/24 drop
        iifname "r-lan" meta nfproto ipv4 ip saddr != 10.43.0.0/24 drop
        iifname { "r-wifi", "r-lan" } oifname "r-up" meta nfproto ipv4 accept
$inter_rule
        iifname "r-up" oifname { "r-wifi", "r-lan" } meta nfproto ipv4 ct state { established, related } ct direction reply accept
        iifname { "r-wifi", "r-lan" } drop
        oifname { "r-wifi", "r-lan" } drop
    }
    chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        oifname "r-up" ip saddr { 10.42.0.0/24, 10.43.0.0/24 } masquerade
    }
}
EOF
}

pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1" >&2; exit 1; }
expect_success() {
    local description="$1"
    shift
    "$@" >/dev/null 2>&1 && pass "$description" || fail "$description"
}
expect_blocked() {
    local description="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        fail "$description"
    fi
    pass "$description"
}

ping4() {
    local namespace="$1" destination="$2"
    ip netns exec "$namespace" ping -4 -c 1 -W 1 "$destination"
}

ping6() {
    local namespace="$1" destination="$2"
    ip netns exec "$namespace" ping -6 -c 1 -W 1 "$destination"
}

apply_firewall false
expect_success "Segment clients can reach the upstream network" ping4 "$wifi" 192.0.2.2
expect_blocked "Wi-Fi and Ethernet segments are isolated by default" ping4 "$wifi" 10.43.0.10
expect_blocked "Untrusted interfaces cannot initiate connections into ENRA segments" ping4 "$untrusted" 10.42.0.10
expect_blocked "The upstream cannot initiate new connections into ENRA segments" ping4 "$upstream" 10.42.0.10
expect_blocked "IPv6 forwarding through ENRA segments is blocked" ping6 "$wifi" fd42:43::2

ip -n "$wifi" address add 10.43.0.99/32 dev c-wifi
expect_blocked "A segment cannot spoof another segment's IPv4 subnet" \
    ip netns exec "$wifi" ping -4 -I 10.43.0.99 -c 1 -W 1 192.0.2.2

apply_firewall true
expect_success "Inter-segment option permits Wi-Fi to Ethernet traffic" ping4 "$wifi" 10.43.0.10
expect_success "Inter-segment option permits Ethernet to Wi-Fi traffic" ping4 "$lan" 10.42.0.10
expect_success "Upstream return traffic remains functional" ping4 "$wifi" 192.0.2.2
expect_blocked "Inter-segment option does not open new upstream-to-segment connections" ping4 "$upstream" 10.42.0.10

printf 'Network-namespace firewall integration tests passed.\n'
