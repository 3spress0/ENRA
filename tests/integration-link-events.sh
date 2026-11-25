#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "$EUID" -ne 0 ]]; then
    printf 'Run this integration test as root.\n' >&2
    exit 1
fi

command -v ip >/dev/null 2>&1 || {
    printf 'Missing test dependency: iproute2.\n' >&2
    exit 1
}

namespace="enra-link-$$"
events="$(mktemp)"
monitor_pid=""

cleanup() {
    if [[ -n "$monitor_pid" ]]; then
        kill "$monitor_pid" >/dev/null 2>&1 || true
        wait "$monitor_pid" 2>/dev/null || true
    fi
    ip netns del "$namespace" >/dev/null 2>&1 || true
    rm -f "$events"
}
trap cleanup EXIT

ip netns add "$namespace"
ip -n "$namespace" link add enra-test0 type veth peer name enra-peer0
ip -n "$namespace" link set lo up
ip -n "$namespace" link set enra-test0 up
ip -n "$namespace" link set enra-peer0 up

ip netns exec "$namespace" ip monitor link >"$events" 2>&1 &
monitor_pid="$!"
sleep 0.5

# Taking the peer down and up changes carrier on enra-test0, as an unplugged
# and reconnected Ethernet cable would.
ip -n "$namespace" link set enra-peer0 down
sleep 0.3
ip -n "$namespace" link set enra-peer0 up

attempts=0
while ! grep -q 'enra-test0' "$events" && (( attempts < 30 )); do
    attempts=$((attempts + 1))
    sleep 0.1
done

if ! grep -q 'enra-test0' "$events"; then
    printf '[FAIL] ip monitor link did not report the simulated carrier change.\n' >&2
    cat "$events" >&2
    exit 1
fi

printf '[PASS] ip monitor link reports Ethernet carrier transitions.\n'
