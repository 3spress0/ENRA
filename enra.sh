#!/usr/bin/env bash
set -Eeuo pipefail

readonly ENRA_VERSION="0.1.0"
readonly CONFIG_DIR="/etc/enra"
readonly CONFIG_FILE="$CONFIG_DIR/enra.conf"
readonly HOSTAPD_FILE="$CONFIG_DIR/hostapd.conf"
readonly BRIDGE_IF="br-enra"
readonly DRIVER_REPO="https://github.com/morrownr/8821au-20210708.git"
readonly DRIVER_DIR="/usr/local/src/enra/8821au-20210708"
readonly INSTALLED_SCRIPT="/usr/local/sbin/enra"

C_CYAN=$'\033[0;36m'
C_WHITE=$'\033[0;37m'
C_GREY=$'\033[0;90m'
C_RED=$'\033[0;31m'
C_GREEN=$'\033[0;32m'
C_RESET=$'\033[0m'

print_banner() {
    printf '%b\n' \
'\033[0;37m   \033[0;36m▄▄\033[0;96m▄▄▄▄▄▄▄\033[0;36m▄\033[0;37m     \033[0;36m▄▄\033[0;96m▄▄▄▄▄▄▄\033[0;36m▄\033[0;37m       \033[0;36m▄▄\033[0;96m▄▄▄▄▄\033[0;36m▄▄▄\033[0;37m       \033[0;36m▄▄\033[0;96m▄▄▄▄▄\033[0;36m▄▄▄\033[0;37m   \033[0m' \
'\033[0;36m░\033[0;96;46m▄\033[0;36m▄\033[0;37m \033[0;36m▀\033[0;96;46m▐████▀\033[0;36m▀\033[0;37m   \033[0;36m░\033[0;96;46m▄\033[0;36m▄\033[0;37m \033[0;36m▀\033[0;96;46m▐████▀\033[0;36m▀\033[0;37m \033[0;36m▄\033[0;96;46m▄\033[0;36m░\033[0;37m \033[0;36m░\033[0;96;46m▄\033[0;36m▄\033[0;37m \033[0;36m▀\033[0;96;46m▀▐███▀\033[0;36m▀\033[0;37m \033[0;36m▄\033[0;96;46m▄\033[0;36m░\033[0;37m \033[0;36m░\033[0;96;46m▄\033[0;36m▄\033[0;37m \033[0;36m▀\033[0;96;46m▀▐███▀\033[0;36m▀\033[0;37m \033[0;36m▄\033[0;96;46m▄\033[0;36m░\033[0m' \
'\033[0;36m░\033[0;96;46m██▀\033[0;37m        \033[0;90m░░\033[0;37m \033[0;36m░\033[0;96;46m██▀\033[0;37m        \033[0;96;46m███\033[0;36m░\033[0;37m \033[0;36m░\033[0;96;46m██░\033[0;36m░\033[0;37m       \033[0;96;46m▄▐█\033[0;36m░\033[0;37m \033[0;36m░\033[0;96;46m██░\033[0;36m░\033[0;37m       \033[0;96;46m▄▐█\033[0;36m░\033[0m' \
'\033[0;36m░\033[0;96;46m██▌\033[0;37m \033[0;90m░░░░░░░░░\033[0;37m \033[0;36m░\033[0;96;46m██▌\033[0;37m \033[0;90m░░░░░░\033[0;37m \033[0;96;46m██▌\033[0;36m░\033[0;37m \033[0;36m░\033[0;96;46m██▒\033[0;36m░\033[0;37m \033[0;90m░░░░\033[0;37m \033[0;36m░\033[0;96;46m███\033[0;36m░\033[0;37m \033[0;36m░\033[0;96;46m██▒\033[0;36m░\033[0;37m \033[0;90m░░░░\033[0;37m \033[0;36m░\033[0;96;46m███\033[0;36m░\033[0m' \
'\033[0;36m░\033[0;96;46m██▀\033[0;37m \033[0;90m░░░░░░░░░\033[0;37m \033[0;36m░\033[0;96;46m██▀\033[0;37m \033[0;90m░░░░░░\033[0;37m \033[0;96;46m▐█▌\033[0;36m░\033[0;37m \033[0;36m░\033[0;96;46m██▓\033[0;36m░\033[0;37m \033[0;90m░░░░\033[0;37m  \033[0;96;46m▐██\033[0;36m░\033[0;37m \033[0;36m░\033[0;96;46m██▓\033[0;36m░\033[0;37m \033[0;90m░░░░\033[0;37m  \033[0;96;46m▐██\033[0;36m░\033[0m' \
'\033[0;36m░\033[0;96;46m▒\033[0;36m▀\033[0;37m \033[0;36m▄▄\033[0;96m▄▄▄\033[0;36m▄\033[0;96m▄\033[0;36m▄\033[0;37m   \033[0;36m░\033[0;96;46m▒\033[0;36m▀\033[0;37m  \033[0;90m░░░░░░\033[0;37m  \033[0;36m▀█░\033[0;37m \033[0;36m░\033[0;96;46m▀\033[0;36m▀\033[0;37m \033[0;36m▄▄\033[0;96m▄▄▄\033[0;36m▄\033[0;96m▄\033[0;36m▄\033[0;37m \033[0;36m▀\033[0;96;46m▀\033[0;36m░\033[0;37m \033[0;36m░\033[0;96;46m▀\033[0;36m▀\033[0;37m \033[0;36m▄▄\033[0;96m▄▄▄\033[0;36m▄\033[0;96m▄\033[0;36m▄\033[0;37m \033[0;36m▀\033[0;96;46m▀\033[0;36m░\033[0m' \
'\033[0;37m   \033[0;36m█\033[0;96;46m▓▓█▓████\033[0;36m█░\033[0;37m    \033[0;90m░░░░░░░░░░\033[0;37m       \033[0;36m█\033[0;96;46m▓▓█▓████\033[0;36m█\033[0;37m       \033[0;36m█\033[0;96;46m▓▓█▓████\033[0;36m█\033[0;37m   \033[0m' \
'\033[0;36m░\033[0;96;46m▄\033[0;36m▄\033[0;37m            \033[0;36m░\033[0;96;46m▄\033[0;36m▄\033[0;37m  \033[0;90m░░░░░░\033[0;37m  \033[0;36m▄\033[0;96;46m█\033[0;36m░\033[0;37m \033[0;36m░█▄\033[0;37m          \033[0;36m▄\033[0;96;46m▄\033[0;36m░\033[0;37m \033[0;36m░█▄\033[0;37m          \033[0;36m▄\033[0;96;46m▄\033[0;36m░\033[0m' \
'\033[0;36m░\033[0;96;46m██▌\033[0;37m \033[0;90m░░░░░░░░░\033[0;37m \033[0;36m░\033[0;96;46m██▌\033[0;37m \033[0;90m░░░░░░\033[0;37m \033[0;96;46m▄██\033[0;36m░\033[0;37m \033[0;36m░\033[0;96;46m▓▌▄\033[0;37m \033[0;90m░░░░░\033[0;37m \033[0;36m░\033[0;96;46m▀██\033[0;36m░\033[0;37m \033[0;36m░\033[0;96;46m▓▌▄\033[0;37m \033[0;90m░░░░░\033[0;37m \033[0;36m░\033[0;96;46m▀██\033[0;36m░\033[0m' \
'\033[0;36m░\033[0;96;46m██▌\033[0;37m \033[0;90m░░░░░░░░░\033[0;37m \033[0;36m░\033[0;96;46m██▌\033[0;37m \033[0;90m░░░░░░\033[0;37m \033[0;96;46m███\033[0;36m░\033[0;37m \033[0;36m░\033[0;96;46m███\033[0;37m \033[0;90m░░░░░\033[0;37m \033[0;36m░\033[0;96;46m▐██\033[0;36m░\033[0;37m \033[0;36m░\033[0;96;46m███\033[0;37m \033[0;90m░░░░░\033[0;37m \033[0;36m░\033[0;96;46m▐██\033[0;36m░\033[0m' \
'\033[0;36m░\033[0;96;46m██▓\033[0;37m        \033[0;90m░░\033[0;37m \033[0;36m░\033[0;96;46m██▓\033[0;37m \033[0;90m░░░░░░\033[0;37m \033[0;96;46m▀██\033[0;36m░\033[0;37m \033[0;36m░\033[0;96;46m█▀█\033[0;37m \033[0;90m░░░░░\033[0;37m \033[0;36m░\033[0;96;46m▀█▀\033[0;36m░\033[0;37m \033[0;36m░\033[0;96;46m█▀█\033[0;37m \033[0;90m░░░░░\033[0;37m \033[0;36m░\033[0;96;46m▀█▀\033[0;36m░\033[0m' \
'\033[0;36m░\033[0;96;46m▒\033[0;36m▀░▄\033[0;96;46m▄▄███▄\033[0;36m▄\033[0;37m   \033[0;36m░\033[0;96;46m▒\033[0;36m▀\033[0;37m  \033[0;90m░░░░░░\033[0;37m  \033[0;36m▀\033[0;96;46m▐\033[0;36m░\033[0;37m \033[0;36m░\033[0;96;46m█\033[0;36m▀\033[0;37m  \033[0;90m░░░░░\033[0;37m   \033[0;36m▀\033[0;96;46m \033[0;36m░\033[0;37m \033[0;36m░\033[0;96;46m█\033[0;36m▀\033[0;37m  \033[0;90m░░░░░\033[0;37m   \033[0;36m▀\033[0;96;46m \033[0;36m░\033[0m'
    printf '%b\n' "$C_CYAN ENRA$C_WHITE: espress0's Network Routing Architecture$C_RESET" \
        "$C_GREY Version $ENRA_VERSION | Debian network infrastructure$C_RESET" ""
}

log() { printf '%b[ENRA]%b %s\n' "$C_CYAN" "$C_RESET" "$*"; }
success() { printf '%b[+]%b %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '%b[!]%b %s\n' "$C_GREY" "$C_RESET" "$*" >&2; }
die() { printf '%b[ERROR]%b %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

require_root() {
    [[ "$EUID" -eq 0 ]] || die "Run as root: sudo ./enra.sh $1"
}

load_config() {
    [[ -f "$CONFIG_FILE" ]] || die "ENRA is not configured. Run: sudo ./enra.sh setup"
    source "$CONFIG_FILE"
}

install_driver() {
    local kernel
    kernel="$(uname -r)"

    if modinfo rtw88_8821au >/dev/null 2>&1 &&
       modinfo -F alias rtw88_8821au 2>/dev/null | grep -qi 'v0BDAp0811'; then
        DRIVER_MODULE="rtw88_8821au"
        log "Using the in-kernel rtw88_8821au driver."
    elif modinfo 8821au >/dev/null 2>&1 &&
         dkms status 2>/dev/null | grep -q 'rtl8821au'; then
        DRIVER_MODULE="8821au"
        log "The RTL8821AU DKMS driver is already installed."
    else
        if [[ ! -e "/lib/modules/$kernel/build" ]]; then
            if ! apt-get install -y "linux-headers-$kernel"; then
                warn "Headers for the running kernel are unavailable."
                apt-get install -y linux-image-amd64 linux-headers-amd64
                die "A matching kernel and headers have been installed. Reboot Debian, then run setup again."
            fi
        fi
        [[ -e "/lib/modules/$kernel/build" ]] || die "Kernel headers are missing for $kernel."

        mkdir -p "$(dirname "$DRIVER_DIR")"
        if [[ ! -d "$DRIVER_DIR/.git" ]]; then
            git clone --depth 1 "$DRIVER_REPO" "$DRIVER_DIR"
        else
            git -C "$DRIVER_DIR" pull --ff-only
        fi

        # Debian 13 compatibility fix documented by the upstream driver maintainer.
        if grep -q '_FW_UNDER_SURVEY' "$DRIVER_DIR/core/rtw_xmit.c"; then
            sed -i 's/_FW_UNDER_SURVEY/WIFI_UNDER_SURVEY/g' "$DRIVER_DIR/core/rtw_xmit.c"
        fi

        log "Building and installing the upstream RTL8821AU DKMS driver."
        if ! (cd "$DRIVER_DIR" && sh ./install-driver.sh NoPrompt); then
            die "DKMS build failed. Inspect /var/lib/dkms/rtl8821au/5.12.5.2/build/make.log"
        fi
        DRIVER_MODULE="8821au"
    fi

    modprobe "$DRIVER_MODULE" || die "Could not load kernel module: $DRIVER_MODULE"
}

choose_wireless_interface() {
    local -a interfaces
    local choice
    WIFI_IF=""
    mapfile -t interfaces < <(iw dev | awk '$1 == "Interface" { print $2 }')

    [[ -n "$(printf '%s' "${interfaces[*]}")" ]] ||
        die "No wireless interface appeared after loading $DRIVER_MODULE. Check USB passthrough and dmesg."

    if (( ${#interfaces[@]} == 1 )); then
        WIFI_IF="${interfaces[0]}"
    else
        printf '\nDetected wireless interfaces:\n'
        select choice in "${interfaces[@]}"; do
            if [[ -n "$choice" ]]; then
                WIFI_IF="$choice"
                break
            fi
        done
    fi

    if ! iw list | grep -Eq '^[[:space:]]*\* AP$'; then
        die "The driver does not advertise AP mode. ENRA will not configure hostapd."
    fi
    success "Wireless interface: $WIFI_IF"
}

choose_uplink_interface() {
    local default_interfaces

    printf '\nAvailable network interfaces:\n'
    ip -br link
    printf '\nIPv4/IPv6 addresses:\n'
    ip -br address
    printf '\nDefault route(s):\n'
    ip route show default
    ip -6 route show default

    read -r -p "Interface connected to the OPNsense LAN Segment (not VMware NAT): " UPLINK_IF
    [[ -n "$UPLINK_IF" ]] || die "No interface selected."
    ip link show dev "$UPLINK_IF" >/dev/null 2>&1 || die "Interface does not exist: $UPLINK_IF"
    [[ "$UPLINK_IF" != "$WIFI_IF" ]] || die "The Wi-Fi interface cannot also be the wired bridge port."

    default_interfaces="$(ip route show default; ip -6 route show default)"
    if grep -Eq "(^|[[:space:]])dev[[:space:]]+$UPLINK_IF([[:space:]]|$)" <<< "$default_interfaces"; then
        die "$UPLINK_IF carries a default route. Select the dedicated OPNsense LAN Segment NIC instead."
    fi

    if ip -o address show dev "$UPLINK_IF" scope global | grep -q .; then
        die "$UPLINK_IF already has a global IP address. Remove its DHCP/static IP configuration before using it as a bridge port."
    fi

    if [[ -L "/sys/class/net/$UPLINK_IF/master" ]]; then
        die "$UPLINK_IF is already attached to another bridge or master."
    fi
    success "Selected wired bridge port: $UPLINK_IF"
}

write_configuration() {
    local ssid_bytes
    printf '\n'
    read -r -p "Wi-Fi network name [espers cool network]: " SSID
    [[ -n "$SSID" ]] || SSID="espers cool network"

    ssid_bytes="$(LC_ALL=C printf '%s' "$SSID" | wc -c)"
    [[ "$ssid_bytes" -ge 1 && "$ssid_bytes" -le 32 ]] || die "SSID must contain 1-32 bytes."
    [[ "$SSID" =~ ^[[:print:]]+$ ]] || die "SSID must contain printable characters only."

    while true; do
        read -r -s -p "WPA2 passphrase (8-63 printable characters): " PASSPHRASE
        printf '\n'
        if [[ "$PASSPHRASE" =~ ^[[:print:]]{8,63}$ ]]; then
            break
        fi
        warn "Passphrase must contain 8-63 printable characters. Try again."
    done

    mkdir -p "$CONFIG_DIR"
    chmod 700 "$CONFIG_DIR"
    {
        printf 'BRIDGE_IF=%q\n' "$BRIDGE_IF"
        printf 'UPLINK_IF=%q\n' "$UPLINK_IF"
        printf 'WIFI_IF=%q\n' "$WIFI_IF"
        printf 'DRIVER_MODULE=%q\n' "$DRIVER_MODULE"
        printf 'SSID=%q\n' "$SSID"
    } > "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"

    cat > "$HOSTAPD_FILE" <<EOF
interface=$WIFI_IF
bridge=$BRIDGE_IF
driver=nl80211
ssid=$SSID
country_code=NL
ieee80211d=1
hw_mode=g
channel=6
ieee80211n=1
wmm_enabled=1
auth_algs=1
wpa=2
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
wpa_passphrase=$PASSPHRASE
EOF
    chmod 600 "$HOSTAPD_FILE"
    unset PASSPHRASE
}

install_systemd_units() {
    install -D -m 0755 "$SELF_PATH" "$INSTALLED_SCRIPT"

    cat > /etc/systemd/system/enra-bridge.service <<'EOF'
[Unit]
Description=ENRA Layer 2 bridge to OPNsense
Wants=network-pre.target
After=network-pre.target systemd-udev-settle.service
Before=enra-ap.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/enra bridge-up
ExecStop=/usr/local/sbin/enra bridge-down

[Install]
WantedBy=multi-user.target
EOF

    cat > /etc/systemd/system/enra-ap.service <<'EOF'
[Unit]
Description=ENRA wireless access point
Requires=enra-bridge.service
After=enra-bridge.service systemd-udev-settle.service

[Service]
Type=simple
ExecStartPre=/usr/local/sbin/enra driver-load
ExecStart=/usr/sbin/hostapd /etc/enra/hostapd.conf
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl disable --now hostapd.service >/dev/null 2>&1 || true
    systemctl daemon-reload
}

setup() {
    require_root setup
    [[ -r /etc/os-release ]] || die "Cannot identify this operating system."
    . /etc/os-release
    [[ "$ID" == "debian" ]] || die "ENRA currently targets Debian. Detected: $PRETTY_NAME"

    print_banner
    log "Installing ENRA dependencies."
    apt-get update
    apt-get install -y build-essential bc dkms git iw rfkill hostapd iproute2 usbutils

    log "Checking USB adapter."
    lsusb | grep -qi '0bda:0811' ||
        die "USB adapter 0bda:0811 was not found. Connect the Realtek adapter to Debian using VMware USB passthrough."

    install_driver
    choose_wireless_interface
    choose_uplink_interface
    write_configuration
    install_systemd_units

    log "Enabling ENRA bridge and access point services."
    systemctl enable enra-bridge.service enra-ap.service
    if ! systemctl start enra-bridge.service enra-ap.service; then
        systemctl --no-pager --full status enra-bridge.service enra-ap.service || true
        journalctl -u enra-bridge.service -u enra-ap.service -n 60 --no-pager || true
        die "ENRA services did not start. Review the output above."
    fi

    success "ENRA setup completed."
    printf 'SSID: %s\n' "$SSID"
    printf 'Bridge: %s <-> %s\n' "$UPLINK_IF" "$WIFI_IF"
    printf 'Security: WPA2-Personal (AES/CCMP)\n'
    printf 'Services: enra-bridge.service, enra-ap.service\n'
    warn "OPNsense must provide DHCP, routing and firewalling on the same LAN Segment."
}

bridge_up() {
    require_root bridge-up
    load_config

    ip link show dev "$UPLINK_IF" >/dev/null 2>&1 || die "Bridge port is missing: $UPLINK_IF"
    if [[ ! -d "/sys/class/net/$BRIDGE_IF/bridge" ]]; then
        ip link add name "$BRIDGE_IF" type bridge stp_state 0
    fi

    if [[ -L "/sys/class/net/$UPLINK_IF/master" ]]; then
        local current_master
        current_master="$(basename "$(readlink -f "/sys/class/net/$UPLINK_IF/master")")"
        [[ "$current_master" == "$BRIDGE_IF" ]] || die "$UPLINK_IF is already attached to $current_master."
    else
        ip link set dev "$UPLINK_IF" master "$BRIDGE_IF"
    fi

    ip link set dev "$UPLINK_IF" up
    ip link set dev "$BRIDGE_IF" up
}

bridge_down() {
    require_root bridge-down
    load_config

    if [[ -L "/sys/class/net/$UPLINK_IF/master" ]]; then
        ip link set dev "$UPLINK_IF" nomaster || true
    fi
    if [[ -d "/sys/class/net/$BRIDGE_IF/bridge" ]]; then
        ip link set dev "$BRIDGE_IF" down || true
        ip link delete dev "$BRIDGE_IF" type bridge || true
    fi
}

driver_load() {
    require_root driver-load
    load_config
    modprobe "$DRIVER_MODULE"

    local attempt
    for attempt in {1..20}; do
        if iw dev | awk '$1 == "Interface" { print $2 }' | grep -Fxq "$WIFI_IF"; then
            return 0
        fi
        sleep 1
    done
    die "Wireless interface $WIFI_IF did not appear after loading $DRIVER_MODULE."
}

status() {
    print_banner
    if [[ ! -f "$CONFIG_FILE" ]]; then
        warn "ENRA is not configured. Run: sudo ./enra.sh setup"
        return 1
    fi
    load_config
    printf 'Kernel: %s\n' "$(uname -r)"
    printf 'Driver module: %s\n' "$DRIVER_MODULE"
    printf 'Wireless interface: %s\n' "$WIFI_IF"
    printf 'Bridge port: %s\n' "$UPLINK_IF"
    printf 'SSID: %s\n\n' "$SSID"
    printf 'Bridge service: '
    systemctl is-active enra-bridge.service || true
    printf 'Access point service: '
    systemctl is-active enra-ap.service || true
    printf '\nNetwork links:\n'
    ip -br link
}

usage() {
    cat <<'EOF'
ENRA - espress0's Network Routing Architecture

Usage:
  sudo ./enra.sh setup    Install the driver and configure the access point
  sudo ./enra.sh start    Start the bridge and wireless access point
  sudo ./enra.sh stop     Stop the access point and remove the bridge
  sudo ./enra.sh status   Display ENRA status
  sudo ./enra.sh logs     Show ENRA service logs

The setup command is interactive. It does not configure DHCP, NAT,
IP forwarding, or firewall rules. Those remain the responsibility of OPNsense.
EOF
}

SELF_PATH="$(readlink -f "$0")"
ACTION="help"
if (( $# > 0 )); then
    ACTION="$1"
fi

case "$ACTION" in
    setup) setup ;;
    start)
        require_root start
        systemctl start enra-bridge.service enra-ap.service
        ;;
    stop)
        require_root stop
        systemctl stop enra-ap.service enra-bridge.service
        ;;
    status) status ;;
    logs) journalctl -u enra-bridge.service -u enra-ap.service -n 100 --no-pager ;;
    bridge-up) bridge_up ;;
    bridge-down) bridge_down ;;
    driver-load) driver_load ;;
    help|-h|--help) usage ;;
    *) usage; die "Unknown command: $ACTION" ;;
esac
