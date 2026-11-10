#!/usr/bin/env bash
set -Eeuo pipefail

readonly ENRA_VERSION="0.2.0"
readonly CONFIG_DIR="/etc/enra"
readonly CONFIG_FILE="$CONFIG_DIR/enra.conf"
readonly HOSTAPD_FILE="$CONFIG_DIR/hostapd.conf"
readonly DNSMASQ_FILE="$CONFIG_DIR/dnsmasq.conf"
readonly BRIDGE_IF="br-enra"
readonly INSTALLED_SCRIPT="/usr/local/sbin/enra"
readonly RTL8821AU_REPO="https://github.com/morrownr/8821au-20210708.git"
readonly RTL8821AU_DIR="/usr/local/src/enra/8821au-20210708"

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

require_root() { [[ "$EUID" -eq 0 ]] || die "Run as root: sudo enra $1"; }
require_systemd() {
    [[ "$(ps -p 1 -o comm= 2>/dev/null | tr -d ' ')" == "systemd" ]] ||
        die "ENRA service integration currently requires systemd."
}
load_config() {
    [[ -f "$CONFIG_FILE" ]] || die "ENRA is not configured. Run: sudo enra setup"
    # shellcheck source=/etc/enra/enra.conf
    source "$CONFIG_FILE"
}

detect_platform() {
    [[ -r /etc/os-release ]] || die "Cannot identify this Linux distribution."
    . /etc/os-release
    DISTRO_ID="${ID:-unknown}"
    DISTRO_LIKE="${ID_LIKE:-}"
    PRETTY_NAME="${PRETTY_NAME:-$DISTRO_ID}"
    case "$DISTRO_ID $DISTRO_LIKE" in
        *debian*|*ubuntu*) PACKAGE_MANAGER="apt" ;;
        *fedora*|*rhel*|*centos*|*rocky*|*almalinux*) PACKAGE_MANAGER="dnf" ;;
        *arch*|*manjaro*|*endeavouros*) PACKAGE_MANAGER="pacman" ;;
        *opensuse*|*suse*) PACKAGE_MANAGER="zypper" ;;
        *) die "Unsupported distribution: $PRETTY_NAME. Supported package families: Debian/Ubuntu, Fedora/RHEL, Arch and openSUSE." ;;
    esac
}

install_packages() {
    case "$PACKAGE_MANAGER:$1" in
        apt:base)
            export DEBIAN_FRONTEND=noninteractive
            apt-get update
            apt-get install -y hostapd iw rfkill iproute2 usbutils wireless-regdb python3
            ;;
        apt:routed) apt-get install -y dnsmasq-base nftables ;;
        apt:build) apt-get install -y build-essential bc dkms git "linux-headers-$(uname -r)" ;;
        dnf:base) dnf install -y hostapd iw rfkill iproute usbutils python3 ;;
        dnf:routed) dnf install -y dnsmasq nftables ;;
        dnf:build) dnf install -y gcc make bc dkms git "kernel-devel-$(uname -r)" ;;
        pacman:base) pacman -Sy --needed --noconfirm hostapd iw rfkill iproute2 usbutils python ;;
        pacman:routed) pacman -S --needed --noconfirm dnsmasq nftables ;;
        pacman:build) pacman -S --needed --noconfirm base-devel bc dkms git linux-headers ;;
        zypper:base)
            zypper --non-interactive refresh
            zypper --non-interactive install --no-recommends hostapd iw rfkill iproute2 usbutils python3
            ;;
        zypper:routed) zypper --non-interactive install --no-recommends dnsmasq nftables ;;
        zypper:build) zypper --non-interactive install --no-recommends gcc make bc dkms git "kernel-devel-$(uname -r)" ;;
    esac
}

wireless_list() {
    iw dev 2>/dev/null | awk '$1 == "Interface" {print $2}'
}
supports_ap_mode() {
    local iface="$1" phy
    phy="$(iw dev "$iface" info 2>/dev/null | awk '$1 == "wiphy" {print "phy"$2; exit}')"
    [[ -n "$phy" ]] || return 1
    iw phy "$phy" info 2>/dev/null |
        awk '/Supported interface modes:/ {found=1; next}
             found && /^[[:space:]]+\*/ {if ($2 == "AP") exit 0; next}
             found && !/^[[:space:]]/ {exit 1}
             END {if (!found) exit 1}'
}

install_rtl8821au() {
    local kernel
    kernel="$(uname -r)"
    install_packages build
    [[ -e "/lib/modules/$kernel/build" ]] || die "Matching kernel headers unavailable for $kernel."
    mkdir -p "$(dirname "$RTL8821AU_DIR")"
    if [[ ! -d "$RTL8821AU_DIR/.git" ]]; then
        git clone --depth 1 "$RTL8821AU_REPO" "$RTL8821AU_DIR"
    else
        git -C "$RTL8821AU_DIR" pull --ff-only
    fi
    if [[ -f "$RTL8821AU_DIR/core/rtw_xmit.c" ]] &&
       grep -q '_FW_UNDER_SURVEY' "$RTL8821AU_DIR/core/rtw_xmit.c"; then
        sed -i 's/_FW_UNDER_SURVEY/WIFI_UNDER_SURVEY/g' "$RTL8821AU_DIR/core/rtw_xmit.c"
    fi
    (cd "$RTL8821AU_DIR" && sh ./install-driver.sh NoPrompt) ||
        die "RTL8821AU DKMS installation failed. Inspect the DKMS build log."
    modprobe 8821au || die "Could not load the 8821au module."
    DRIVER_MODULE="8821au"
}

discover_driver() {
    local usb_list="$1"
    if [[ -n "$(wireless_list)" ]]; then return 0; fi
    if [[ "$usb_list" == *"0bda:0811"* ]]; then
        case "$PACKAGE_MANAGER" in
            apt)
                if [[ "$DISTRO_ID" == "debian" ]]; then
                    apt-get install -y firmware-realtek || warn "firmware-realtek could not be installed; verify Debian non-free-firmware is enabled."
                else
                    apt-get install -y linux-firmware || warn "linux-firmware could not be installed automatically."
                fi
                ;;
            dnf) dnf install -y linux-firmware || warn "linux-firmware could not be installed automatically." ;;
            pacman) pacman -S --needed --noconfirm linux-firmware || warn "linux-firmware could not be installed automatically." ;;
            zypper) zypper --non-interactive install kernel-firmware-realtek || warn "Realtek firmware package could not be installed automatically." ;;
        esac
        modprobe rtw88_8821au >/dev/null 2>&1 || true
        modprobe 8821au >/dev/null 2>&1 || true
        sleep 2
        if [[ -n "$(wireless_list)" ]]; then return 0; fi
        warn "RTL8821AU USB adapter detected, but no wireless interface appeared."
        read -r -p "Install the upstream RTL8821AU DKMS driver? [y/N] " answer
        [[ "$answer" =~ ^[Yy]$ ]] || die "Install a working driver/firmware, verify it with iw dev, then rerun ENRA."
        install_rtl8821au
        [[ -n "$(wireless_list)" ]] || die "No interface appeared after driver installation. Check dmesg and USB passthrough."
        return 0
    fi
    die "No wireless interface found. Install the correct driver/firmware, verify it with iw dev, then rerun ENRA."
}

choose_wireless_interface() {
    local choices
    choices="$(wireless_list)"
    [[ -n "$choices" ]] || die "No wireless interface was detected."
    printf '\nDetected wireless interfaces:\n%s\n' "$choices"
    if [[ "$(printf '%s\n' "$choices" | wc -l)" -eq 1 ]]; then
        WIFI_IF="$(printf '%s\n' "$choices" | head -n 1)"
    else
        read -r -p "Enter the wireless interface to use: " WIFI_IF
        grep -Fxq "$WIFI_IF" <<< "$choices" || die "That interface was not detected."
    fi
    supports_ap_mode "$WIFI_IF" || die "$WIFI_IF does not advertise AP mode. Use an adapter/driver with AP-mode support."
    success "Access-point interface: $WIFI_IF"
}

choose_network_mode() {
    local answer
    printf '\nNetwork mode:\n'
    printf '  1) bridge - join an existing LAN; its router provides DHCP/routing\n'
    printf '  2) routed - create a separate IPv4 subnet with DHCP and NAT\n'
    read -r -p "Select mode [1]: " answer
    case "$answer" in
        ""|1|bridge) NETWORK_MODE="bridge" ;;
        2|routed) NETWORK_MODE="routed" ;;
        *) die "Invalid network mode." ;;
    esac
}

choose_interface() {
    local prompt="$1" protect_default="$2" selected
    printf '\nAvailable interfaces:\n' >&2
    ip -br link >&2
    read -r -p "$prompt: " selected
    [[ -n "$selected" ]] || die "No interface selected."
    ip link show dev "$selected" >/dev/null 2>&1 || die "Interface does not exist: $selected"
    if [[ "$protect_default" == "yes" ]] &&
       { ip route show default | grep -Eq "(^|[[:space:]])dev[[:space:]]+$selected([[:space:]]|$)" ||
         ip -6 route show default | grep -Eq "(^|[[:space:]])dev[[:space:]]+$selected([[:space:]]|$)"; }; then
        die "$selected carries a default route. Choose a dedicated LAN/backhaul interface."
    fi
    printf '%s' "$selected"
}

validate_bridge_port() {
    local iface="$1"
    [[ ! -L "/sys/class/net/$iface/master" ]] || die "$iface is already attached to a bridge/master."
    if ip -o address show dev "$iface" scope global | grep -q .; then
        die "$iface has a global IP address. A bridge port must not retain its own L3 address."
    fi
    if grep -RqsE "^[[:space:]]*(auto|allow-hotplug|iface)[[:space:]]+$iface([[:space:]]|$)" \
        /etc/network/interfaces /etc/network/interfaces.d 2>/dev/null; then
        die "$iface is configured by ifupdown. Remove that stanza before assigning it to ENRA."
    fi
}

configure_interfaces() {
    if [[ "$NETWORK_MODE" == "bridge" ]]; then
        UPLINK_IF="$(choose_interface "Interface connected to the LAN being bridged" yes)"
        [[ "$UPLINK_IF" != "$WIFI_IF" ]] || die "Wired and wireless interfaces must be different."
        validate_bridge_port "$UPLINK_IF"
        AP_GATEWAY="" AP_PREFIX="" AP_NETWORK="" DHCP_START="" DHCP_END="" DNS_UPSTREAM=""
    else
        UPLINK_IF="$(choose_interface "Internet/upstream interface" no)"
        [[ "$UPLINK_IF" != "$WIFI_IF" ]] || die "AP and uplink interfaces must be different."
        read -r -p "AP gateway IPv4 [10.42.0.1]: " AP_GATEWAY
        AP_GATEWAY="${AP_GATEWAY:-10.42.0.1}"
        read -r -p "AP subnet prefix [24]: " AP_PREFIX
        AP_PREFIX="${AP_PREFIX:-24}"
        [[ "$AP_PREFIX" =~ ^([8-9]|[12][0-9]|30)$ ]] || die "Use an IPv4 prefix between 8 and 30."
        read -r -p "DHCP range start [10.42.0.50]: " DHCP_START
        DHCP_START="${DHCP_START:-10.42.0.50}"
        read -r -p "DHCP range end [10.42.0.200]: " DHCP_END
        DHCP_END="${DHCP_END:-10.42.0.200}"
        read -r -p "Upstream DNS server [1.1.1.1]: " DNS_UPSTREAM
        DNS_UPSTREAM="${DNS_UPSTREAM:-1.1.1.1}"
        AP_NETWORK="$(python3 - "$AP_GATEWAY" "$AP_PREFIX" "$DHCP_START" "$DHCP_END" "$DNS_UPSTREAM" <<'PY'
import ipaddress, sys
gateway = ipaddress.IPv4Address(sys.argv[1])
network = ipaddress.IPv4Network((gateway, int(sys.argv[2])), strict=False)
start, end, dns = (ipaddress.IPv4Address(value) for value in sys.argv[3:6])
if start not in network or end not in network or start > end:
    raise SystemExit("DHCP range must be ordered and inside the AP subnet.")
if gateway in (network.network_address, network.broadcast_address) or start <= gateway <= end:
    raise SystemExit("Gateway must be a usable address outside the DHCP range.")
print(network.with_prefixlen)
PY
)" || die "Invalid routed network values."
        ip route show "$AP_NETWORK" 2>/dev/null | grep -q . &&
            die "AP subnet overlaps a route already present on this machine."
        systemctl is-active --quiet dnsmasq.service &&
            die "The system dnsmasq.service is active. Resolve that DNS/DHCP conflict before choosing routed mode."
    fi
}

configure_radio() {
    local answer default_channel
    read -r -p "Regulatory country code (ISO alpha-2) [NL]: " COUNTRY_CODE
    COUNTRY_CODE="${COUNTRY_CODE:-NL}"
    COUNTRY_CODE="${COUNTRY_CODE^^}"
    [[ "$COUNTRY_CODE" =~ ^[A-Z]{2}$ ]] || die "Country code must contain two letters."
    printf '\nRadio band:\n  1) 2.4 GHz\n  2) 5 GHz\n'
    read -r -p "Select band [1]: " answer
    case "$answer" in
        ""|1) BAND="2.4"; default_channel=6 ;;
        2) BAND="5"; default_channel=36 ;;
        *) die "ENRA currently configures 2.4 GHz and 5 GHz APs." ;;
    esac
    read -r -p "Channel [$default_channel]: " CHANNEL
    CHANNEL="${CHANNEL:-$default_channel}"
    [[ "$CHANNEL" =~ ^[0-9]{1,3}$ ]] || die "Channel must be numeric."
}

configure_security() {
    local answer
    printf '\nWireless security:\n'
    printf '  1) WPA3-Personal (SAE, PMF required)\n'
    printf '  2) WPA2-Personal (PSK, AES/CCMP)\n'
    printf '  3) WPA2/WPA3 transition mode\n'
    read -r -p "Select security [1]: " answer
    case "$answer" in
        ""|1) SECURITY="wpa3" ;;
        2) SECURITY="wpa2" ;;
        3) SECURITY="transition" ;;
        *) die "Invalid security mode." ;;
    esac
    while true; do
        read -r -s -p "Wi-Fi passphrase (8-63 printable ASCII characters): " PASSPHRASE
        printf '\n'
        [[ "$PASSPHRASE" =~ ^[[:print:]]{8,63}$ ]] && break
        warn "Passphrase must contain 8-63 printable ASCII characters."
    done
}

write_configuration() {
    local ssid_bytes ssid_hex
    read -r -p "Wi-Fi network name [espers cool network]: " SSID
    SSID="${SSID:-espers cool network}"
    ssid_bytes="$(LC_ALL=C printf '%s' "$SSID" | wc -c)"
    [[ "$ssid_bytes" -ge 1 && "$ssid_bytes" -le 32 ]] || die "SSID must contain 1-32 bytes."
    [[ "$SSID" =~ ^[[:print:]]+$ ]] || die "SSID must contain printable ASCII characters."
    ssid_hex="$(printf '%s' "$SSID" | od -An -tx1 | tr -d ' \n')"
    mkdir -p "$CONFIG_DIR"
    chmod 700 "$CONFIG_DIR"
    {
        printf 'NETWORK_MODE=%q\nWIFI_IF=%q\nUPLINK_IF=%q\nSSID=%q\nSSID_HEX=%q\n' \
            "$NETWORK_MODE" "$WIFI_IF" "$UPLINK_IF" "$SSID" "$ssid_hex"
        printf 'COUNTRY_CODE=%q\nBAND=%q\nCHANNEL=%q\nSECURITY=%q\n' "$COUNTRY_CODE" "$BAND" "$CHANNEL" "$SECURITY"
        printf 'AP_GATEWAY=%q\nAP_PREFIX=%q\nAP_NETWORK=%q\n' "$AP_GATEWAY" "$AP_PREFIX" "$AP_NETWORK"
        printf 'DHCP_START=%q\nDHCP_END=%q\nDNS_UPSTREAM=%q\nDRIVER_MODULE=%q\n' \
            "$DHCP_START" "$DHCP_END" "$DNS_UPSTREAM" "${DRIVER_MODULE:-}"
    } > "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    write_hostapd_config
    [[ "$NETWORK_MODE" != "routed" ]] || write_dnsmasq_config
    unset PASSPHRASE
}

write_hostapd_config() {
    local radio security
    if [[ "$BAND" == "2.4" ]]; then
        radio=$'hw_mode=g\nieee80211n=1'
    else
        radio=$'hw_mode=a\nieee80211n=1\nieee80211ac=1'
    fi
    case "$SECURITY" in
        wpa3) security=$'wpa=2\nwpa_key_mgmt=SAE\nrsn_pairwise=CCMP\nieee80211w=2\nsae_pwe=2' ;;
        wpa2) security=$'wpa=2\nwpa_key_mgmt=WPA-PSK\nrsn_pairwise=CCMP\nieee80211w=1' ;;
        transition) security=$'wpa=2\nwpa_key_mgmt=WPA-PSK SAE\nrsn_pairwise=CCMP\nieee80211w=1\nsae_pwe=2' ;;
        *) die "Unsupported security mode: $SECURITY" ;;
    esac
    {
        printf 'interface=%s\n' "$WIFI_IF"
        [[ "$NETWORK_MODE" != "bridge" ]] || printf 'bridge=%s\n' "$BRIDGE_IF"
        printf 'driver=nl80211\nssid2=%s\n' "$SSID_HEX"
        printf 'country_code=%s\nieee80211d=1\nchannel=%s\n' "$COUNTRY_CODE" "$CHANNEL"
        printf 'wmm_enabled=1\nauth_algs=1\n%s\n%s\nwpa_passphrase=%s\n' "$radio" "$security" "$PASSPHRASE"
    } > "$HOSTAPD_FILE"
    chmod 600 "$HOSTAPD_FILE"
}

write_dnsmasq_config() {
    cat > "$DNSMASQ_FILE" <<EOF
interface=$WIFI_IF
bind-dynamic
except-interface=lo
no-resolv
server=$DNS_UPSTREAM
dhcp-authoritative
dhcp-range=$DHCP_START,$DHCP_END,12h
dhcp-option=option:router,$AP_GATEWAY
dhcp-option=option:dns-server,$AP_GATEWAY
EOF
    chmod 600 "$DNSMASQ_FILE"
}

configure_network_manager() {
    command -v nmcli >/dev/null 2>&1 || return 0
    mkdir -p /etc/NetworkManager/conf.d
    if [[ "$NETWORK_MODE" == "bridge" ]]; then
        cat > /etc/NetworkManager/conf.d/90-enra-unmanaged.conf <<EOF
[keyfile]
unmanaged-devices=interface-name:$WIFI_IF;interface-name:$UPLINK_IF;interface-name:$BRIDGE_IF
EOF
        nmcli device set "$UPLINK_IF" managed no >/dev/null 2>&1 || true
    else
        cat > /etc/NetworkManager/conf.d/90-enra-unmanaged.conf <<EOF
[keyfile]
unmanaged-devices=interface-name:$WIFI_IF
EOF
    fi
    nmcli general reload >/dev/null 2>&1 || true
    nmcli device set "$WIFI_IF" managed no >/dev/null 2>&1 || true
}

configure_networkd_unmanaged() {
    systemctl is-active --quiet systemd-networkd.service || return 0
    mkdir -p /etc/systemd/network
    local iface="$WIFI_IF"
    cat > "/etc/systemd/network/00-enra-$iface.network" <<EOF
[Match]
Name=$iface

[Link]
Unmanaged=yes
EOF
    if [[ "$NETWORK_MODE" == "bridge" ]]; then
        for iface in "$UPLINK_IF" "$BRIDGE_IF"; do
            cat > "/etc/systemd/network/00-enra-$iface.network" <<EOF
[Match]
Name=$iface

[Link]
Unmanaged=yes
EOF
        done
    fi
    networkctl reload
    networkctl reconfigure "$WIFI_IF" >/dev/null 2>&1 || true
    [[ "$NETWORK_MODE" != "bridge" ]] || networkctl reconfigure "$UPLINK_IF" >/dev/null 2>&1 || true
}

install_services() {
    local hostapd_bin dnsmasq_bin
    hostapd_bin="$(command -v hostapd)"
    dnsmasq_bin="$(command -v dnsmasq 2>/dev/null || true)"
    install -D -m 0755 "$SELF_PATH" "$INSTALLED_SCRIPT"
    cat > /etc/systemd/system/enra-network.service <<'EOF'
[Unit]
Description=ENRA network configuration
Wants=network-pre.target
After=network-pre.target NetworkManager.service systemd-networkd.service
Before=enra-ap.service enra-dnsmasq.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/enra network-up
ExecStop=/usr/local/sbin/enra network-down

[Install]
WantedBy=multi-user.target
EOF
    cat > /etc/systemd/system/enra-ap.service <<EOF
[Unit]
Description=ENRA wireless access point
Requires=enra-network.service
After=enra-network.service

[Service]
Type=simple
ExecStartPre=/usr/local/sbin/enra driver-load
ExecStart=$hostapd_bin $HOSTAPD_FILE
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    if [[ "$NETWORK_MODE" == "routed" ]]; then
        [[ -n "$dnsmasq_bin" ]] || die "dnsmasq binary was not installed."
        cat > /etc/systemd/system/enra-dnsmasq.service <<EOF
[Unit]
Description=ENRA DHCP and DNS service
Requires=enra-network.service enra-ap.service
After=enra-network.service enra-ap.service

[Service]
Type=simple
ExecStart=$dnsmasq_bin --no-daemon --conf-file=$DNSMASQ_FILE --pid-file=/run/enra-dnsmasq.pid
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    fi
    systemctl daemon-reload
}

setup() {
    require_root setup
    require_systemd
    detect_platform
    print_banner
    install_packages base
    command -v iw >/dev/null 2>&1 || die "iw is required."
    command -v hostapd >/dev/null 2>&1 || die "hostapd is required."
    command -v ip >/dev/null 2>&1 || die "iproute2 is required."
    local usb_list
    usb_list="$(lsusb 2>/dev/null || true)"
    discover_driver "$usb_list"
    choose_wireless_interface
    choose_network_mode
    configure_interfaces
    if [[ "$NETWORK_MODE" == "routed" ]]; then
        install_packages routed
        systemctl disable --now dnsmasq.service >/dev/null 2>&1 || true
    fi
    configure_radio
    configure_security
    write_configuration
    configure_network_manager
    configure_networkd_unmanaged
    install_services
    systemctl enable enra-network.service enra-ap.service
    if [[ "$NETWORK_MODE" == "routed" ]]; then
        systemctl enable enra-dnsmasq.service
    else
        systemctl disable enra-dnsmasq.service >/dev/null 2>&1 || true
    fi
    systemctl restart enra-network.service || die "Network setup failed. Check journalctl -u enra-network."
    systemctl restart enra-ap.service || {
        journalctl -u enra-ap.service -n 60 --no-pager || true
        die "hostapd failed. Check driver, firmware and AP-mode capabilities."
    }
    if [[ "$NETWORK_MODE" == "routed" ]]; then
        systemctl restart enra-dnsmasq.service || {
            journalctl -u enra-dnsmasq.service -n 60 --no-pager || true
            die "ENRA DHCP/DNS service failed."
        }
    fi
    success "ENRA setup completed."
    printf 'Mode: %s\nWireless interface: %s\nSSID: %s\nBand/channel: %s GHz / %s\nSecurity: %s\n' \
        "$NETWORK_MODE" "$WIFI_IF" "$SSID" "$BAND" "$CHANNEL" "$SECURITY"
}

network_up() {
    require_root network-up
    load_config
    ip link show dev "$WIFI_IF" >/dev/null 2>&1 || die "Wireless interface not found: $WIFI_IF"
    ip link set dev "$WIFI_IF" up
    if [[ "$NETWORK_MODE" == "bridge" ]]; then
        ip link show dev "$UPLINK_IF" >/dev/null 2>&1 || die "Bridge uplink not found: $UPLINK_IF"
        [[ -d "/sys/class/net/$BRIDGE_IF/bridge" ]] || ip link add name "$BRIDGE_IF" type bridge stp_state 0
        if [[ -L "/sys/class/net/$UPLINK_IF/master" ]]; then
            local master
            master="$(basename "$(readlink -f "/sys/class/net/$UPLINK_IF/master")")"
            [[ "$master" == "$BRIDGE_IF" ]] || die "$UPLINK_IF is already attached to $master."
        else
            ip link set dev "$UPLINK_IF" master "$BRIDGE_IF"
        fi
        ip link set dev "$UPLINK_IF" up
        ip link set dev "$BRIDGE_IF" up
    else
        ip address replace "$AP_GATEWAY/$AP_PREFIX" dev "$WIFI_IF"
        sysctl -w net.ipv4.ip_forward=1 >/dev/null
        printf 'net.ipv4.ip_forward=1\n' > /etc/sysctl.d/90-enra-forward.conf
        nft list table inet enra >/dev/null 2>&1 && nft delete table inet enra
        nft -f - <<EOF
table inet enra {
    chain forward {
        type filter hook forward priority filter; policy accept;
        iifname "$WIFI_IF" oifname "$UPLINK_IF" accept
        iifname "$UPLINK_IF" oifname "$WIFI_IF" ct state established,related accept
        iifname "$WIFI_IF" drop
    }
    chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        oifname "$UPLINK_IF" ip saddr $AP_NETWORK masquerade
    }
}
EOF
    fi
}

network_down() {
    require_root network-down
    load_config
    if [[ "$NETWORK_MODE" == "bridge" ]]; then
        if [[ -L "/sys/class/net/$UPLINK_IF/master" ]]; then
            ip link set dev "$UPLINK_IF" nomaster || true
        fi
        if [[ -d "/sys/class/net/$BRIDGE_IF/bridge" ]]; then
            ip link set dev "$BRIDGE_IF" down || true
            ip link delete dev "$BRIDGE_IF" type bridge || true
        fi
    else
        nft list table inet enra >/dev/null 2>&1 && nft delete table inet enra || true
        ip address del "$AP_GATEWAY/$AP_PREFIX" dev "$WIFI_IF" 2>/dev/null || true
        # Do not disable IP forwarding globally; another service may depend on it.
    fi
}

driver_load() {
    require_root driver-load
    load_config
    if [[ -n "$DRIVER_MODULE" ]]; then modprobe "$DRIVER_MODULE"; fi
    local remaining=20
    while (( remaining > 0 )); do
        iw dev | awk '$1 == "Interface" {print $2}' | grep -Fxq "$WIFI_IF" && return 0
        remaining=$((remaining - 1))
        sleep 1
    done
    die "Wireless interface $WIFI_IF did not appear."
}

status() {
    print_banner
    [[ -f "$CONFIG_FILE" ]] || die "ENRA is not configured. Run: sudo enra setup"
    load_config
    printf 'Mode: %s\nWireless interface: %s\nUplink: %s\nSSID: %s\nBand/channel: %s GHz / %s\nSecurity: %s\n\n' \
        "$NETWORK_MODE" "$WIFI_IF" "$UPLINK_IF" "$SSID" "$BAND" "$CHANNEL" "$SECURITY"
    printf 'Network service: '; systemctl is-active enra-network.service || true
    printf 'Access point service: '; systemctl is-active enra-ap.service || true
    if [[ "$NETWORK_MODE" == "routed" ]]; then
        printf 'DHCP/DNS service: '; systemctl is-active enra-dnsmasq.service || true
    fi
    printf '\nNetwork links:\n'; ip -br link
    printf '\nRecent hostapd log:\n'; journalctl -u enra-ap.service -n 12 --no-pager
}
logs() { journalctl -u enra-network.service -u enra-ap.service -u enra-dnsmasq.service -n 120 --no-pager; }
start() {
    require_root start
    load_config
    systemctl start enra-network.service enra-ap.service
    [[ "$NETWORK_MODE" != "routed" ]] || systemctl start enra-dnsmasq.service
}
stop() {
    require_root stop
    systemctl stop enra-dnsmasq.service enra-ap.service enra-network.service 2>/dev/null || true
}
usage() {
    cat <<'EOF'
ENRA - espress0's Network Routing Architecture

Usage:
  sudo enra setup     Interactive installation and configuration
  sudo enra status    Show configuration and service health
  sudo enra start     Start ENRA services
  sudo enra stop      Stop ENRA services
  sudo enra logs      Show ENRA service logs

Network modes:
  bridge              Bridge Wi-Fi clients to an existing LAN/router
  routed              Create a separate IPv4 subnet with DHCP and NAT

Security:
  WPA3-Personal       SAE with required PMF
  WPA2-Personal       PSK with AES/CCMP
  Transition          WPA2/WPA3 mixed authentication

Supported package families: Debian/Ubuntu, Fedora/RHEL, Arch and openSUSE.
systemd and a wireless driver with AP-mode support are required.
EOF
}

SELF_PATH="$(readlink -f "$0")"
ACTION="${1:-help}"
case "$ACTION" in
    setup) setup ;;
    status) status ;;
    logs) logs ;;
    start) start ;;
    stop) stop ;;
    network-up) network_up ;;
    network-down) network_down ;;
    driver-load) driver_load ;;
    help|-h|--help) usage ;;
    *) usage; die "Unknown command: $ACTION" ;;
esac
