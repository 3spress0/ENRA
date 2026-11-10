#!/usr/bin/env bash
set -Eeuo pipefail

readonly ENRA_VERSION="0.3.0"
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

    # Migrate existing single-Wi-Fi routed configurations in memory.
    if [[ "$NETWORK_MODE" == "routed" && -z "${SEGMENT_IFACES+x}" ]]; then
        SEGMENT_IFACES=("$WIFI_IF")
        SEGMENT_NAMES=("Wi-Fi")
        SEGMENT_GATEWAYS=("$AP_GATEWAY")
        SEGMENT_PREFIXES=("$AP_PREFIX")
        SEGMENT_NETWORKS=("$AP_NETWORK")
        SEGMENT_DHCP_STARTS=("$DHCP_START")
        SEGMENT_DHCP_ENDS=("$DHCP_END")
    fi
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
        apt:build)
            export DEBIAN_FRONTEND=noninteractive
            if apt-get install -y build-essential bc dkms git "linux-headers-$(uname -r)"; then
                return 0
            fi
            warn "Headers for the running kernel ($(uname -r)) are unavailable. Installing Debian's current kernel and matching headers instead."
            apt-get install -y linux-image-amd64 linux-headers-amd64 build-essential bc dkms git ||
                die "Could not install a supported Debian kernel and its build dependencies."
            [[ -e "/lib/modules/$(uname -r)/build" ]] || {
                warn "A newer kernel and matching headers are installed. Reboot, then rerun ENRA setup to build the Wi-Fi driver."
                return 2
            }
            ;;
        dnf:base) dnf install -y hostapd iw rfkill iproute usbutils python3 ;;
        dnf:routed) dnf install -y dnsmasq nftables ;;
        dnf:build)
            if dnf install -y gcc make bc dkms git "kernel-devel-$(uname -r)"; then
                return 0
            fi
            warn "Matching kernel-devel is unavailable. Installing the current kernel and development package."
            dnf install -y kernel kernel-devel gcc make bc dkms git ||
                die "Could not install kernel development dependencies."
            [[ -e "/lib/modules/$(uname -r)/build" ]] || {
                warn "A newer kernel and matching development files are installed. Reboot, then rerun ENRA setup."
                return 2
            }
            ;;
        pacman:base) pacman -Sy --needed --noconfirm hostapd iw rfkill iproute2 usbutils python ;;
        pacman:routed) pacman -S --needed --noconfirm dnsmasq nftables ;;
        pacman:build) pacman -S --needed --noconfirm base-devel bc dkms git linux-headers ;;
        zypper:base)
            zypper --non-interactive refresh
            zypper --non-interactive install --no-recommends hostapd iw rfkill iproute2 usbutils python3
            ;;
        zypper:routed) zypper --non-interactive install --no-recommends dnsmasq nftables ;;
        zypper:build)
            if zypper --non-interactive install --no-recommends gcc make bc dkms git "kernel-devel-$(uname -r)"; then
                return 0
            fi
            warn "Matching kernel development files are unavailable. Install the current kernel and development packages."
            zypper --non-interactive install --no-recommends kernel-default kernel-default-devel gcc make bc dkms git ||
                die "Could not install kernel development dependencies."
            [[ -e "/lib/modules/$(uname -r)/build" ]] || {
                warn "A newer kernel and matching development files are installed. Reboot, then rerun ENRA setup."
                return 2
            }
            ;;
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

install_rtl8821au_firmware() {
    log "Checking firmware package for RTL8821AU."
    case "$PACKAGE_MANAGER:$DISTRO_ID" in
        apt:debian)
            apt-get install -y firmware-realtek ||
                warn "firmware-realtek unavailable. Debian may need the non-free-firmware repository component enabled."
            ;;
        apt:*)
            apt-get install -y linux-firmware ||
                warn "linux-firmware could not be installed automatically."
            ;;
        dnf:*)
            dnf install -y linux-firmware ||
                warn "linux-firmware could not be installed automatically."
            ;;
        pacman:*)
            pacman -S --needed --noconfirm linux-firmware ||
                warn "linux-firmware could not be installed automatically."
            ;;
        zypper:*)
            zypper --non-interactive install kernel-firmware-realtek ||
                warn "kernel-firmware-realtek could not be installed automatically."
            ;;
    esac
}

install_rtl8821au() {
    local kernel
    kernel="$(uname -r)"
    install_packages build || return $?
    [[ -e "/lib/modules/$kernel/build" ]] || {
        warn "Matching kernel headers are unavailable for $kernel."
        return 2
    }
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
    local usb_list="$1" result
    if [[ -n "$(wireless_list)" ]]; then return 0; fi
    if [[ "$usb_list" == *"0bda:0811"* ]]; then
        install_rtl8821au_firmware
        modprobe rtw88_8821au >/dev/null 2>&1 || true
        modprobe 8821au >/dev/null 2>&1 || true
        sleep 2
        if [[ -n "$(wireless_list)" ]]; then return 0; fi
        warn "RTL8821AU USB adapter detected, but no wireless interface appeared."
        read -r -p "Install the upstream RTL8821AU DKMS driver? [y/N] " answer
        if [[ ! "$answer" =~ ^[Yy]$ ]]; then
            warn "Wireless driver installation skipped. Connect a supported adapter or install its driver, then rerun ENRA."
            return 1
        fi
        if install_rtl8821au; then
            [[ -n "$(wireless_list)" ]] && return 0
            warn "The driver installed, but no wireless interface appeared. Check dmesg and USB passthrough."
            return 1
        else
            result=$?
            return "$result"
        fi
    fi
    warn "No wireless interface found. ENRA has installed its base dependencies but cannot configure an access point yet."
    warn "Connect a supported Wi-Fi adapter, install its Linux driver/firmware, verify with 'iw dev', then rerun ENRA."
    return 1
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



validate_routed_port() {
    local iface="$1" i expected
    [[ "$iface" =~ ^[[:alnum:]_.:-]{1,15}$ ]] || die "Unsupported interface name: $iface"
    [[ ! -L "/sys/class/net/$iface/master" ]] || die "$iface is already attached to a bridge/master."
    if iw dev 2>/dev/null | awk '$1 == "Interface" {print $2}' | grep -Fxq "$iface"; then
        die "$iface is wireless. Additional routed segments currently require dedicated Ethernet interfaces."
    fi

    # A segment already managed by the previous ENRA configuration may keep
    # its assigned address during an in-place setup update.
    for ((i = 0; i < ${#PREVIOUS_SEGMENT_IFACES[@]}; i++)); do
        if [[ "$iface" == "${PREVIOUS_SEGMENT_IFACES[$i]}" ]]; then
            expected="${PREVIOUS_SEGMENT_GATEWAYS[$i]}/${PREVIOUS_SEGMENT_PREFIXES[$i]}"
            if ip -4 -o address show dev "$iface" 2>/dev/null | awk '{print $4}' | grep -Fxq "$expected"; then
                return 0
            fi
        fi
    done

    if ip -o address show dev "$iface" scope global | grep -q .; then
        die "$iface already has a global IP address. Use a dedicated, unconfigured LAN interface."
    fi
    if grep -RqsE "^[[:space:]]*(auto|allow-hotplug|iface)[[:space:]]+$iface([[:space:]]|$)" \
        /etc/network/interfaces /etc/network/interfaces.d 2>/dev/null; then
        die "$iface is configured by ifupdown. Remove that stanza before assigning it to an ENRA segment."
    fi
}
validate_segment_network() {
    local gateway="$1" prefix="$2" start="$3" end="$4" dns="$5" network
    shift 5
    network="$(python3 - "$gateway" "$prefix" "$start" "$end" "$dns" "$@" <<'PY'
import ipaddress, sys

try:
    gateway = ipaddress.IPv4Address(sys.argv[1])
    prefix = int(sys.argv[2])
    start = ipaddress.IPv4Address(sys.argv[3])
    end = ipaddress.IPv4Address(sys.argv[4])
    ipaddress.IPv4Address(sys.argv[5])
    if not 8 <= prefix <= 30:
        raise ValueError("Subnet prefix must be between 8 and 30.")
    network = ipaddress.IPv4Network((gateway, prefix), strict=False)
    if gateway in (network.network_address, network.broadcast_address):
        raise ValueError("Gateway must be a usable address in the subnet.")
    if start not in network or end not in network or start > end:
        raise ValueError("DHCP range must be ordered and inside the segment subnet.")
    if start in (network.network_address, network.broadcast_address) or end in (network.network_address, network.broadcast_address):
        raise ValueError("DHCP range cannot include the network or broadcast address.")
    if start <= gateway <= end:
        raise ValueError("Gateway must be outside the DHCP range.")
    for existing in sys.argv[6:]:
        if network.overlaps(ipaddress.IPv4Network(existing)):
            raise ValueError(f"Segment subnet overlaps another ENRA segment: {existing}")
    print(network.with_prefixlen)
except ValueError as error:
    raise SystemExit(str(error))
PY
)" || return 1
    if ip route show "$network" 2>/dev/null | grep -q .; then
        local previous_network allowed=no
        for previous_network in "${PREVIOUS_SEGMENT_NETWORKS[@]}"; do
            [[ "$previous_network" != "$network" ]] || allowed=yes
        done
        if [[ "$allowed" != "yes" ]]; then
            printf 'Subnet %s overlaps a route already present on this machine.\n' "$network" >&2
            return 1
        fi
    fi
    printf '%s' "$network"
}


configure_interfaces() {
    local segment_count selected i default_gateway gateway prefix start end network existing
    if [[ "$NETWORK_MODE" == "bridge" ]]; then
        UPLINK_IF="$(choose_interface "Interface connected to the LAN being bridged" yes)"
        [[ "$UPLINK_IF" != "$WIFI_IF" ]] || die "Wired and wireless interfaces must be different."
        validate_bridge_port "$UPLINK_IF"
        AP_GATEWAY="" AP_PREFIX="" AP_NETWORK="" DHCP_START="" DHCP_END="" DNS_UPSTREAM=""
        SEGMENT_IFACES=() SEGMENT_NAMES=() SEGMENT_GATEWAYS=() SEGMENT_PREFIXES=()
        SEGMENT_NETWORKS=() SEGMENT_DHCP_STARTS=() SEGMENT_DHCP_ENDS=()
        return 0
    fi

    UPLINK_IF="$(choose_interface "Internet/upstream interface" no)"
    [[ "$UPLINK_IF" != "$WIFI_IF" ]] || die "AP and uplink interfaces must be different."

    DNS_UPSTREAM=""
    read -r -p "Upstream DNS server [1.1.1.1]: " DNS_UPSTREAM
    DNS_UPSTREAM="${DNS_UPSTREAM:-1.1.1.1}"

    SEGMENT_IFACES=("$WIFI_IF")
    SEGMENT_NAMES=("Wi-Fi")
    SEGMENT_GATEWAYS=()
    SEGMENT_PREFIXES=()
    SEGMENT_NETWORKS=()
    SEGMENT_DHCP_STARTS=()
    SEGMENT_DHCP_ENDS=()

    read -r -p "Wi-Fi segment gateway IPv4 [10.42.0.1]: " gateway
    gateway="${gateway:-10.42.0.1}"
    read -r -p "Wi-Fi segment subnet prefix [24]: " prefix
    prefix="${prefix:-24}"
    read -r -p "Wi-Fi DHCP range start [10.42.0.50]: " start
    start="${start:-10.42.0.50}"
    read -r -p "Wi-Fi DHCP range end [10.42.0.200]: " end
    end="${end:-10.42.0.200}"
    network="$(validate_segment_network "$gateway" "$prefix" "$start" "$end" "$DNS_UPSTREAM")" ||
        die "Invalid Wi-Fi segment network settings."
    SEGMENT_GATEWAYS+=("$gateway")
    SEGMENT_PREFIXES+=("$prefix")
    SEGMENT_NETWORKS+=("$network")
    SEGMENT_DHCP_STARTS+=("$start")
    SEGMENT_DHCP_ENDS+=("$end")

    printf '\\nEach Ethernet segment needs a dedicated interface and receives its own isolated IPv4 subnet.\\n'
    read -r -p "Additional Ethernet LAN segments [0]: " segment_count
    segment_count="${segment_count:-0}"
    [[ "$segment_count" =~ ^(0|[1-9][0-9]*)$ ]] || die "Enter a whole number of additional Ethernet segments."
    (( segment_count <= 32 )) || die "ENRA supports up to 32 additional Ethernet segments per instance."

    for ((i = 1; i <= segment_count; i++)); do
        printf '\nEthernet segment %s of %s\n' "$i" "$segment_count"
        selected="$(choose_interface "Dedicated Ethernet interface for segment $i" yes)"
        [[ "$selected" != "$UPLINK_IF" && "$selected" != "$WIFI_IF" ]] ||
            die "$selected is already assigned to another ENRA role."
        for existing in "${SEGMENT_IFACES[@]}"; do
            [[ "$selected" != "$existing" ]] || die "$selected is already assigned to another ENRA segment."
        done
        validate_routed_port "$selected"

        default_gateway="10.$((42 + i)).0.1"
        read -r -p "Segment $i gateway IPv4 [$default_gateway]: " gateway
        gateway="${gateway:-$default_gateway}"
        read -r -p "Segment $i subnet prefix [24]: " prefix
        prefix="${prefix:-24}"
        read -r -p "Segment $i DHCP range start [10.$((42 + i)).0.50]: " start
        start="${start:-10.$((42 + i)).0.50}"
        read -r -p "Segment $i DHCP range end [10.$((42 + i)).0.200]: " end
        end="${end:-10.$((42 + i)).0.200}"
        network="$(validate_segment_network "$gateway" "$prefix" "$start" "$end" "$DNS_UPSTREAM" "${SEGMENT_NETWORKS[@]}")" ||
            die "Invalid network settings for Ethernet segment $i."

        SEGMENT_IFACES+=("$selected")
        SEGMENT_NAMES+=("Ethernet $i")
        SEGMENT_GATEWAYS+=("$gateway")
        SEGMENT_PREFIXES+=("$prefix")
        SEGMENT_NETWORKS+=("$network")
        SEGMENT_DHCP_STARTS+=("$start")
        SEGMENT_DHCP_ENDS+=("$end")
    done

    AP_GATEWAY="${SEGMENT_GATEWAYS[0]}"
    AP_PREFIX="${SEGMENT_PREFIXES[0]}"
    AP_NETWORK="${SEGMENT_NETWORKS[0]}"
    DHCP_START="${SEGMENT_DHCP_STARTS[0]}"
    DHCP_END="${SEGMENT_DHCP_ENDS[0]}"

    if systemctl is-active --quiet dnsmasq.service; then
        die "The system dnsmasq.service is active. Resolve that DNS/DHCP conflict before choosing routed mode."
    fi
    return 0
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


write_config_array() {
    local name="$1" value index=0
    shift
    printf '%s=(' "$name"
    for value in "$@"; do
        printf '[%s]=%q ' "$index" "$value"
        index=$((index + 1))
    done
    printf ')\n'
}


write_configuration() {
    local ssid_bytes
    read -r -p "Wi-Fi network name [espers cool network]: " SSID
    SSID="${SSID:-espers cool network}"
    ssid_bytes="$(LC_ALL=C printf '%s' "$SSID" | wc -c)"
    [[ "$ssid_bytes" -ge 1 && "$ssid_bytes" -le 32 ]] || die "SSID must contain 1-32 bytes."
    [[ "$SSID" =~ ^[[:print:]]+$ ]] || die "SSID must contain printable ASCII characters."
    SSID_HEX="$(printf '%s' "$SSID" | od -An -tx1 | tr -d ' \n')"
    mkdir -p "$CONFIG_DIR"
    chmod 700 "$CONFIG_DIR"
    {
        printf 'NETWORK_MODE=%q\nWIFI_IF=%q\nUPLINK_IF=%q\nSSID=%q\nSSID_HEX=%q\n' \
            "$NETWORK_MODE" "$WIFI_IF" "$UPLINK_IF" "$SSID" "$SSID_HEX"
        printf 'COUNTRY_CODE=%q\nBAND=%q\nCHANNEL=%q\nSECURITY=%q\n' "$COUNTRY_CODE" "$BAND" "$CHANNEL" "$SECURITY"
        printf 'AP_GATEWAY=%q\nAP_PREFIX=%q\nAP_NETWORK=%q\n' "$AP_GATEWAY" "$AP_PREFIX" "$AP_NETWORK"
        printf 'DHCP_START=%q\nDHCP_END=%q\nDNS_UPSTREAM=%q\nDRIVER_MODULE=%q\n' \
            "$DHCP_START" "$DHCP_END" "$DNS_UPSTREAM" "${DRIVER_MODULE:-}"
        if [[ "$NETWORK_MODE" == "routed" ]]; then
            write_config_array SEGMENT_IFACES "${SEGMENT_IFACES[@]}"
            write_config_array SEGMENT_NAMES "${SEGMENT_NAMES[@]}"
            write_config_array SEGMENT_GATEWAYS "${SEGMENT_GATEWAYS[@]}"
            write_config_array SEGMENT_PREFIXES "${SEGMENT_PREFIXES[@]}"
            write_config_array SEGMENT_NETWORKS "${SEGMENT_NETWORKS[@]}"
            write_config_array SEGMENT_DHCP_STARTS "${SEGMENT_DHCP_STARTS[@]}"
            write_config_array SEGMENT_DHCP_ENDS "${SEGMENT_DHCP_ENDS[@]}"
        fi
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
    local i tag netmask
    {
        printf 'bind-dynamic\nexcept-interface=lo\nno-resolv\nserver=%s\ndhcp-authoritative\n' "$DNS_UPSTREAM"
        for ((i = 0; i < ${#SEGMENT_IFACES[@]}; i++)); do
            tag="enra_segment_$i"
            netmask="$(python3 -c 'import ipaddress,sys; print(ipaddress.IPv4Network("0.0.0.0/" + sys.argv[1]).netmask)' "${SEGMENT_PREFIXES[$i]}")"
            printf 'interface=%s\n' "${SEGMENT_IFACES[$i]}"
            printf 'dhcp-range=set:%s,%s,%s,%s,12h\n' "$tag" "${SEGMENT_DHCP_STARTS[$i]}" "${SEGMENT_DHCP_ENDS[$i]}" "$netmask"
            printf 'dhcp-option=tag:%s,option:router,%s\n' "$tag" "${SEGMENT_GATEWAYS[$i]}"
            printf 'dhcp-option=tag:%s,option:dns-server,%s\n' "$tag" "${SEGMENT_GATEWAYS[$i]}"
        done
    } > "$DNSMASQ_FILE"
    chmod 600 "$DNSMASQ_FILE"
}

configure_network_manager() {
    command -v nmcli >/dev/null 2>&1 || return 0
    mkdir -p /etc/NetworkManager/conf.d
    local unmanaged iface
    if [[ "$NETWORK_MODE" == "bridge" ]]; then
        unmanaged="interface-name:$WIFI_IF;interface-name:$UPLINK_IF;interface-name:$BRIDGE_IF"
        nmcli device set "$UPLINK_IF" managed no >/dev/null 2>&1 || true
    else
        unmanaged="interface-name:${SEGMENT_IFACES[0]}"
        for iface in "${SEGMENT_IFACES[@]:1}"; do
            unmanaged+=";interface-name:$iface"
        done
    fi
    cat > /etc/NetworkManager/conf.d/90-enra-unmanaged.conf <<EOF
[keyfile]
unmanaged-devices=$unmanaged
EOF
    nmcli general reload >/dev/null 2>&1 || true
    if [[ "$NETWORK_MODE" == "bridge" ]]; then
        nmcli device set "$WIFI_IF" managed no >/dev/null 2>&1 || true
    else
        for iface in "${SEGMENT_IFACES[@]}"; do
            nmcli device set "$iface" managed no >/dev/null 2>&1 || true
        done
    fi
}

configure_networkd_unmanaged() {
    systemctl is-active --quiet systemd-networkd.service || return 0
    mkdir -p /etc/systemd/network
    local iface
    local interfaces=()
    if [[ "$NETWORK_MODE" == "bridge" ]]; then
        interfaces=("$WIFI_IF" "$UPLINK_IF" "$BRIDGE_IF")
    else
        interfaces=("${SEGMENT_IFACES[@]}")
    fi
    for iface in "${interfaces[@]}"; do
        cat > "/etc/systemd/network/00-enra-$iface.network" <<EOF
[Match]
Name=$iface

[Link]
Unmanaged=yes
EOF
    done
    networkctl reload
    for iface in "${interfaces[@]}"; do
        networkctl reconfigure "$iface" >/dev/null 2>&1 || true
    done
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
    PREVIOUS_SEGMENT_IFACES=()
    PREVIOUS_SEGMENT_GATEWAYS=()
    PREVIOUS_SEGMENT_PREFIXES=()
    PREVIOUS_SEGMENT_NETWORKS=()
    if [[ -r "$CONFIG_FILE" ]]; then
        load_config
        if [[ "${NETWORK_MODE:-}" == "routed" ]]; then
            PREVIOUS_SEGMENT_IFACES=("${SEGMENT_IFACES[@]}")
            PREVIOUS_SEGMENT_GATEWAYS=("${SEGMENT_GATEWAYS[@]}")
            PREVIOUS_SEGMENT_PREFIXES=("${SEGMENT_PREFIXES[@]}")
            PREVIOUS_SEGMENT_NETWORKS=("${SEGMENT_NETWORKS[@]}")
        fi
    fi
    command -v iw >/dev/null 2>&1 || die "iw is required."
    command -v hostapd >/dev/null 2>&1 || die "hostapd is required."
    command -v ip >/dev/null 2>&1 || die "iproute2 is required."
    local usb_list
    usb_list="$(lsusb 2>/dev/null || true)"
    if discover_driver "$usb_list"; then
        :
    else
        local driver_result=$?
        if [[ "$driver_result" -eq 2 ]]; then
            warn "ENRA setup paused because a kernel update is required. Reboot and run './enra.sh setup' again."
        else
            warn "ENRA prerequisites are installed, but setup is not configured. Rerun './enra.sh setup' after resolving the wireless interface."
        fi
        return 0
    fi
    choose_wireless_interface
    choose_network_mode
    configure_interfaces
    if [[ "$NETWORK_MODE" == "routed" ]]; then
        install_packages routed
        if systemctl is-active --quiet dnsmasq.service; then
            die "dnsmasq.service became active during package installation. Stop and inspect that service before running ENRA routed mode."
        fi
    fi
    configure_radio
    configure_security
    write_configuration
    configure_network_manager
    configure_networkd_unmanaged
    install_services
    # Only ENRA-owned units are managed here. Debian may intentionally mask
    # the vendor hostapd.service; ENRA runs hostapd directly via enra-ap.service.
    systemctl unmask enra-network.service enra-ap.service
    if [[ "$NETWORK_MODE" == "routed" ]]; then
        systemctl unmask enra-dnsmasq.service
    fi
    systemctl daemon-reload
    log "Enabling ENRA services..."
    systemctl enable enra-network.service enra-ap.service
    if [[ "$NETWORK_MODE" == "routed" ]]; then
        systemctl enable enra-dnsmasq.service
    else
        systemctl disable enra-dnsmasq.service >/dev/null 2>&1 || true
    fi
    log "Starting ENRA network service..."
    systemctl restart enra-network.service || die "Network setup failed. Check journalctl -u enra-network.service."
    log "Starting ENRA access point service..."
    systemctl restart enra-ap.service || {
        journalctl -u enra-ap.service -n 60 --no-pager || true
        die "hostapd failed. Check driver, firmware and AP-mode capabilities."
    }
    if [[ "$NETWORK_MODE" == "routed" ]]; then
        log "Starting ENRA DHCP/DNS service..."
        systemctl restart enra-dnsmasq.service || {
            journalctl -u enra-dnsmasq.service -n 60 --no-pager || true
            die "ENRA DHCP/DNS service failed."
        }
    fi
    success "ENRA setup completed."
    printf 'Mode: %s\nWireless interface: %s\nSSID: %s\nBand/channel: %s GHz / %s\nSecurity: %s\n' \
        "$NETWORK_MODE" "$WIFI_IF" "$SSID" "$BAND" "$CHANNEL" "$SECURITY"
    if [[ "$NETWORK_MODE" == "routed" ]]; then
        printf 'Routed segments: %s\n' "${#SEGMENT_IFACES[@]}"
        local i
        for ((i = 0; i < ${#SEGMENT_IFACES[@]}; i++)); do
            printf '  %s: %s -> %s (%s)\n' "${SEGMENT_NAMES[$i]}" "${SEGMENT_IFACES[$i]}" \
                "${SEGMENT_GATEWAYS[$i]}" "${SEGMENT_NETWORKS[$i]}"
        done
    fi
    printf 'ENRA services: enra-network.service, enra-ap.service'
    [[ "$NETWORK_MODE" != "routed" ]] || printf ', enra-dnsmasq.service'
    printf '\nRun "enra status" to inspect service health.\n'
}


network_up() {
    require_root network-up
    load_config
    if [[ "$NETWORK_MODE" == "bridge" ]]; then
        ip link show dev "$WIFI_IF" >/dev/null 2>&1 || die "Wireless interface not found: $WIFI_IF"
        ip link show dev "$UPLINK_IF" >/dev/null 2>&1 || die "Bridge uplink not found: $UPLINK_IF"
        ip link set dev "$WIFI_IF" up
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
        return 0
    fi

    local i iface segment_if_set="" segment_network_set="" separator=""
    for ((i = 0; i < ${#SEGMENT_IFACES[@]}; i++)); do
        iface="${SEGMENT_IFACES[$i]}"
        ip link show dev "$iface" >/dev/null 2>&1 || die "ENRA segment interface not found: $iface"
        ip link set dev "$iface" up
        ip address replace "${SEGMENT_GATEWAYS[$i]}/${SEGMENT_PREFIXES[$i]}" dev "$iface"
        segment_if_set+="$separator\"$iface\""
        segment_network_set+="$separator${SEGMENT_NETWORKS[$i]}"
        separator=", "
    done

    install -d -m 700 /run/enra
    if [[ ! -f /run/enra/ip_forward.previous ]]; then
        sysctl -n net.ipv4.ip_forward > /run/enra/ip_forward.previous
        chmod 600 /run/enra/ip_forward.previous
    fi
    sysctl -w net.ipv4.ip_forward=1 >/dev/null

    if nft list table inet enra >/dev/null 2>&1; then
        [[ -f /run/enra/nft-table-owned ]] ||
            die "The nftables table inet enra already exists and is not owned by this ENRA instance. Inspect it before continuing."
        nft delete table inet enra
        rm -f /run/enra/nft-table-owned
    fi

    nft -f - <<EOF
table inet enra {
    chain forward {
        type filter hook forward priority filter; policy accept;
        ct state established,related accept
        iifname { $segment_if_set } oifname "$UPLINK_IF" accept
        iifname { $segment_if_set } drop
        iifname "$UPLINK_IF" oifname { $segment_if_set } drop
    }
    chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        oifname "$UPLINK_IF" ip saddr { $segment_network_set } masquerade
    }
}
EOF
    touch /run/enra/nft-table-owned
    chmod 600 /run/enra/nft-table-owned
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
        if [[ -f /run/enra/nft-table-owned ]]; then
            nft list table inet enra >/dev/null 2>&1 && nft delete table inet enra || true
            rm -f /run/enra/nft-table-owned
        fi
        local iface i
        for ((i = 0; i < ${#SEGMENT_IFACES[@]}; i++)); do
            iface="${SEGMENT_IFACES[$i]}"
            ip address del "${SEGMENT_GATEWAYS[$i]}/${SEGMENT_PREFIXES[$i]}" dev "$iface" 2>/dev/null || true
        done
        if [[ -f /run/enra/ip_forward.previous ]]; then
            local previous_forward
            previous_forward="$(cat /run/enra/ip_forward.previous)"
            if [[ "$previous_forward" == "0" || "$previous_forward" == "1" ]]; then
                sysctl -w "net.ipv4.ip_forward=$previous_forward" >/dev/null || true
            fi
            rm -f /run/enra/ip_forward.previous
        fi
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

service_report() {
    local label="$1" unit="$2" active enabled
    active="$(systemctl is-active "$unit" 2>/dev/null || true)"
    enabled="$(systemctl is-enabled "$unit" 2>/dev/null || true)"
    printf '  %-26s %-12s (startup: %s)\n' "$label" "${active:-not-found}" "${enabled:-not-found}"
}


status() {
    print_banner
    [[ -f "$CONFIG_FILE" ]] || die "ENRA is not configured. Run: sudo enra setup"
    load_config
    printf 'Mode: %s\nWireless interface: %s\nUplink: %s\nSSID: %s\nBand/channel: %s GHz / %s\nSecurity: %s\n\n' \
        "$NETWORK_MODE" "$WIFI_IF" "$UPLINK_IF" "$SSID" "$BAND" "$CHANNEL" "$SECURITY"

    if [[ "$NETWORK_MODE" == "routed" ]]; then
        printf 'Routed network segments:\n'
        local i
        for ((i = 0; i < ${#SEGMENT_IFACES[@]}; i++)); do
            printf '  %-16s %-12s gateway %-18s subnet %s\n' \
                "${SEGMENT_NAMES[$i]}" "${SEGMENT_IFACES[$i]}" \
                "${SEGMENT_GATEWAYS[$i]}" "${SEGMENT_NETWORKS[$i]}"
            printf '    DHCP: %s - %s\n' "${SEGMENT_DHCP_STARTS[$i]}" "${SEGMENT_DHCP_ENDS[$i]}"
        done
        printf 'Upstream DNS: %s\n\n' "$DNS_UPSTREAM"
    fi

    printf 'ENRA-managed services (active state and boot setting):\n'
    service_report "Network" enra-network.service
    service_report "Access point (hostapd)" enra-ap.service
    if [[ "$NETWORK_MODE" == "routed" ]]; then
        service_report "DHCP/DNS (dnsmasq)" enra-dnsmasq.service
    fi

    printf '\nNetwork addresses:\n'; ip -br addr || true
    printf '\nWireless interface state:\n'; iw dev || true
    printf '\nENRA logs:\n'; journalctl -u enra-network.service -u enra-ap.service -u enra-dnsmasq.service -n 30 --no-pager || true

    printf '\nNote: ENRA uses its own enra-ap.service and (in routed mode) enra-dnsmasq.service.\n'
    printf 'The distribution units hostapd.service and dnsmasq.service are not used by ENRA.\n'
}
validate_check() {
    case "$1" in
        pass) printf '  [PASS] %s\n' "$2" ;;
        warn) printf '  [WARN] %s\n' "$2" ;;
        fail) printf '  [FAIL] %s\n' "$2"; VALIDATE_FAILURES=$((VALIDATE_FAILURES + 1)) ;;
    esac
}

validate_service() {
    local label="$1" unit="$2" active enabled
    if ! systemctl cat "$unit" >/dev/null 2>&1; then
        validate_check fail "$label unit is missing: $unit"
        return
    fi
    active="$(systemctl is-active "$unit" 2>/dev/null || true)"
    enabled="$(systemctl is-enabled "$unit" 2>/dev/null || true)"
    if [[ "$active" == "active" ]]; then
        validate_check pass "$label service is active."
    else
        validate_check fail "$label service is ${active:-unknown}. Inspect: journalctl -u $unit -n 60 --no-pager"
    fi
    case "$enabled" in
        enabled|enabled-runtime) validate_check pass "$label service is enabled at boot." ;;
        *) validate_check fail "$label service is not enabled at boot (state: ${enabled:-unknown})." ;;
    esac
}


validate() {
    require_root validate
    require_systemd
    VALIDATE_FAILURES=0
    print_banner
    printf 'ENRA configuration validation\n\n'

    if [[ ! -r "$CONFIG_FILE" ]]; then
        validate_check fail "Configuration file is missing or unreadable: $CONFIG_FILE"
        printf '\nValidation result: FAIL - %s issue(s).\n' "$VALIDATE_FAILURES"
        return 1
    fi

    load_config
    local item i
    for item in NETWORK_MODE WIFI_IF UPLINK_IF SSID SSID_HEX COUNTRY_CODE BAND CHANNEL SECURITY; do
        [[ -n "${!item:-}" ]] &&
            validate_check pass "Configuration value $item is present." ||
            validate_check fail "Configuration value $item is missing."
    done

    case "$NETWORK_MODE" in
        bridge|routed) validate_check pass "Network mode is $NETWORK_MODE." ;;
        *) validate_check fail "Invalid network mode: ${NETWORK_MODE:-unset}." ;;
    esac

    for item in ip iw hostapd systemctl; do
        command -v "$item" >/dev/null 2>&1 &&
            validate_check pass "Required command found: $item." ||
            validate_check fail "Required command is missing: $item."
    done

    if [[ -n "$WIFI_IF" ]] && ip link show dev "$WIFI_IF" >/dev/null 2>&1; then
        validate_check pass "Wireless interface exists: $WIFI_IF."
        supports_ap_mode "$WIFI_IF" &&
            validate_check pass "$WIFI_IF advertises AP mode." ||
            validate_check fail "$WIFI_IF does not advertise AP mode."
        if iw dev "$WIFI_IF" info 2>/dev/null | grep -qE '^[[:space:]]*type AP$'; then
            validate_check pass "$WIFI_IF is operating in AP mode."
        else
            validate_check warn "$WIFI_IF is not currently in AP mode. Check enra-ap.service."
        fi
    else
        validate_check fail "Wireless interface is missing: ${WIFI_IF:-unset}."
    fi

    if [[ -n "$UPLINK_IF" ]] && ip link show dev "$UPLINK_IF" >/dev/null 2>&1; then
        validate_check pass "Upstream interface exists: $UPLINK_IF."
    else
        validate_check fail "Upstream interface is missing: ${UPLINK_IF:-unset}."
    fi

    [[ -s "$HOSTAPD_FILE" ]] &&
        validate_check pass "ENRA hostapd configuration exists." ||
        validate_check fail "ENRA hostapd configuration is missing or empty: $HOSTAPD_FILE"

    if [[ "$NETWORK_MODE" == "routed" ]]; then
        local segment_count="${#SEGMENT_IFACES[@]}"
        (( segment_count > 0 )) &&
            validate_check pass "Configured routed segments: $segment_count." ||
            validate_check fail "No routed network segments are configured."

        local segment_arrays_valid=yes
        if [[ "$segment_count" -ne "${#SEGMENT_NAMES[@]}" ||
              "$segment_count" -ne "${#SEGMENT_GATEWAYS[@]}" ||
              "$segment_count" -ne "${#SEGMENT_PREFIXES[@]}" ||
              "$segment_count" -ne "${#SEGMENT_NETWORKS[@]}" ||
              "$segment_count" -ne "${#SEGMENT_DHCP_STARTS[@]}" ||
              "$segment_count" -ne "${#SEGMENT_DHCP_ENDS[@]}" ]]; then
            validate_check fail "Routed segment configuration arrays have different lengths."
            segment_arrays_valid=no
        fi

        if [[ "$segment_arrays_valid" == "yes" ]]; then
        for ((i = 0; i < segment_count; i++)); do
            if ip link show dev "${SEGMENT_IFACES[$i]}" >/dev/null 2>&1; then
                validate_check pass "Segment ${SEGMENT_NAMES[$i]} interface exists: ${SEGMENT_IFACES[$i]}."
            else
                validate_check fail "Segment ${SEGMENT_NAMES[$i]} interface is missing: ${SEGMENT_IFACES[$i]}."
            fi
            if ip -4 -o address show dev "${SEGMENT_IFACES[$i]}" 2>/dev/null |
                awk '{print $4}' | grep -Fxq "${SEGMENT_GATEWAYS[$i]}/${SEGMENT_PREFIXES[$i]}"; then
                validate_check pass "Segment ${SEGMENT_NAMES[$i]} gateway ${SEGMENT_GATEWAYS[$i]}/${SEGMENT_PREFIXES[$i]} is assigned."
            else
                validate_check fail "Segment ${SEGMENT_NAMES[$i]} gateway is not assigned to ${SEGMENT_IFACES[$i]}."
            fi
            [[ -n "${SEGMENT_NETWORKS[$i]}" && -n "${SEGMENT_DHCP_STARTS[$i]}" && -n "${SEGMENT_DHCP_ENDS[$i]}" ]] &&
                validate_check pass "Segment ${SEGMENT_NAMES[$i]} has a network and DHCP range." ||
                validate_check fail "Segment ${SEGMENT_NAMES[$i]} has incomplete network settings."
        done
        fi

        if command -v dnsmasq >/dev/null 2>&1; then
            validate_check pass "dnsmasq executable is installed."
            if [[ -s "$DNSMASQ_FILE" ]] && dnsmasq --test --conf-file="$DNSMASQ_FILE" >/dev/null 2>&1; then
                validate_check pass "ENRA dnsmasq configuration passes its syntax check."
            else
                validate_check fail "ENRA dnsmasq configuration is missing or invalid: $DNSMASQ_FILE"
            fi
        else
            validate_check fail "dnsmasq executable is missing (Debian package: dnsmasq-base)."
        fi

        [[ "$(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo 0)" == "1" ]] &&
            validate_check pass "IPv4 forwarding is enabled." ||
            validate_check fail "IPv4 forwarding is disabled."

        nft list table inet enra >/dev/null 2>&1 &&
            validate_check pass "ENRA nftables table is loaded." ||
            validate_check fail "ENRA nftables table is missing. Check enra-network.service."

        if [[ -n "$UPLINK_IF" ]] && ip route show default dev "$UPLINK_IF" 2>/dev/null | grep -q .; then
            validate_check pass "Default route uses upstream interface $UPLINK_IF."
        else
            validate_check warn "No default route currently uses $UPLINK_IF; routed clients may not have internet access."
        fi
    elif [[ "$NETWORK_MODE" == "bridge" ]]; then
        ip link show dev "$BRIDGE_IF" >/dev/null 2>&1 &&
            validate_check pass "ENRA bridge exists: $BRIDGE_IF." ||
            validate_check fail "ENRA bridge is missing: $BRIDGE_IF."
    fi

    printf '\nENRA-managed services:\n'
    validate_service "Network" enra-network.service
    validate_service "Access point" enra-ap.service
    if [[ "$NETWORK_MODE" == "routed" ]]; then
        validate_service "DHCP/DNS" enra-dnsmasq.service
    fi

    printf '\nValidation result: '
    if (( VALIDATE_FAILURES == 0 )); then
        printf 'PASS - no blocking issues found.\n'
        return 0
    fi
    printf 'FAIL - %s issue(s) need attention.\n' "$VALIDATE_FAILURES"
    printf 'Run "enra logs" for ENRA service logs.\n'
    return 1
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
  sudo enra /validate  Check configuration, interfaces, firewall and services
  sudo enra start     Start ENRA services
  sudo enra stop      Stop ENRA services
  sudo enra logs      Show ENRA service logs

Network modes:
  bridge              Bridge Wi-Fi clients to an existing LAN/router
  routed              Create isolated IPv4 segments with DHCP and NAT

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
    validate|/validate) validate ;;
    logs) logs ;;
    start) start ;;
    stop) stop ;;
    network-up) network_up ;;
    network-down) network_down ;;
    driver-load) driver_load ;;
    help|-h|--help) usage ;;
    *) usage; die "Unknown command: $ACTION" ;;
esac
