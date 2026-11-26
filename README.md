# ENRA

\`\`\`text
   ▄▄▄▄▄▄▄▄▄▄     ▄▄▄▄▄▄▄▄▄▄       ▄▄▄▄▄▄▄▄▄▄       ▄▄▄▄▄▄▄▄▄▄
░▄▄ ▀▐████▀▀   ░▄▄ ▀▐████▀▀ ▄▄░ ░▄▄ ▀▀▐███▀▀ ▄▄░ ░▄▄ ▀▀▐███▀▀ ▄▄░
░██▀        ░░ ░██▀        ███░ ░██░░       ▄▐█░ ░██░░       ▄▐█░
░██▌ ░░░░░░░░░ ░██▌ ░░░░░░ ██▌░ ░██▒░ ░░░░ ░███░ ░██▒░ ░░░░ ░███░
░██▀ ░░░░░░░░░ ░██▀ ░░░░░░ ▐█▌░ ░██▓░ ░░░░  ▐██░ ░██▓░ ░░░░  ▐██░
░▒▀ ▄▄▄▄▄▄▄▄   ░▒▀  ░░░░░░  ▀█░ ░▀▀ ▄▄▄▄▄▄▄▄ ▀▀░ ░▀▀ ▄▄▄▄▄▄▄▄ ▀▀░
   █▓▓█▓█████░    ░░░░░░░░░░       █▓▓█▓█████       █▓▓█▓█████
░▄▄            ░▄▄  ░░░░░░  ▄█░ ░█▄          ▄▄░ ░█▄          ▄▄░
░██▌ ░░░░░░░░░ ░██▌ ░░░░░░ ▄██░ ░▓▌▄ ░░░░░ ░▀██░ ░▓▌▄ ░░░░░ ░▀██░
░██▌ ░░░░░░░░░ ░██▌ ░░░░░░ ███░ ░███ ░░░░░ ░▐██░ ░███ ░░░░░ ░▐██░
░██▓        ░░ ░██▓ ░░░░░░ ▀██░ ░█▀█ ░░░░░ ░▀█▀░ ░█▀█ ░░░░░ ░▀█▀░
░▒▀░▄▄▄███▄▄   ░▒▀  ░░░░░░  ▀▐░ ░█▀  ░░░░░   ▀ ░ ░█▀  ░░░░░   ▀ ░
\`\`\`

**espress0's Network Routing Architecture**  
`Version 0.8.0` | Linux network infrastructure

ENRA turns a compatible Linux computer into a configurable Wi-Fi access point and network router. It discovers network adapters, guides you through setup, configures the required services and keeps the access point running when a cable or adapter is temporarily disconnected.

## Get started

Open a terminal on the Linux system that will run ENRA and execute:

\`\`\`bash
curl -fsSL https://raw.githubusercontent.com/3spress0/ENRA/main/install.sh | sudo bash
\`\`\`

The installer downloads ENRA, installs its dependencies and launches the guided setup when an interactive terminal is available. You do not need to clone the repository or edit configuration files.

The setup wizard helps you:

1. Choose a Wi-Fi adapter that supports access-point mode.
2. Choose whether ENRA should extend your existing network or create a separate one.
3. Select the upstream or bridge Ethernet adapter where required.
4. Choose the Wi-Fi country, band, channel and security mode.
5. Set the Wi-Fi network name and password.
6. Apply the configuration and start ENRA.

Press Enter to accept a recommended default where one is offered. Keep a copy of the Wi-Fi password: ENRA stores it in a root-only configuration file and does not display it again after setup.

To install without starting the wizard, run the installer with \`--install-only\`:

\`\`\`bash
sudo ./install.sh --install-only
sudo enra setup
\`\`\`

When the installer is piped into a non-interactive shell, it installs ENRA without starting the wizard. Start setup later with \`sudo enra setup\`.

## Requirements

- A systemd-based Linux distribution using APT, DNF, Pacman or Zypper.
- A Wi-Fi adapter and Linux driver that expose access-point mode through nl80211.
- An internet connection during installation.
- Root privileges to install packages and configure networking.
- A separate wired adapter for bridge mode, or an upstream network connection for routed mode.

ENRA supports these package families:

| Package manager | Distribution families |
|---|---|
| APT | Debian, Ubuntu and derivatives |
| DNF | Fedora, RHEL, Rocky Linux, AlmaLinux and derivatives |
| Pacman | Arch Linux, Manjaro, EndeavourOS and derivatives |
| Zypper | openSUSE |

This is package-manager support, not a guarantee that every distribution release, kernel or adapter has been tested. The Wi-Fi chipset, driver and firmware must support AP mode. WPA3 additionally requires compatible hostapd, driver, firmware and client devices.

Non-systemd distributions, OpenWrt, BSD, Windows and macOS are not supported by this installer.

## Choose a network mode

The setup wizard asks how connected devices should reach your network.

| Mode | What ENRA does | Choose it when |
|---|---|---|
| **Bridge** | Adds Wi-Fi to an existing Ethernet LAN. Your current router or firewall continues to provide DHCP, DNS, routing and network policy. | You want an additional access point on the same network. |
| **Routed** | Creates a separate IPv4 network and provides DHCP, routing, NAT and firewall isolation. | You want ENRA clients on a separate network behind your existing router. |

### Bridge mode

\`\`\`text
Wi-Fi clients
     |
  ENRA access point
     |
    br-enra
     |
Dedicated Ethernet adapter
     |
Existing router / firewall
(DHCP, DNS, routing and policy)
\`\`\`

Bridge mode requires a dedicated wired adapter connected to the LAN you want to extend. ENRA protects the adapter carrying the Linux host's current default route. Do not choose the computer's only management or internet connection as the bridge port.

The upstream router controls the network policy for wireless clients. Bridge mode does not create a separate guest-network security boundary.

### Routed mode

\`\`\`text
Wi-Fi clients ---------+
                       |
Optional wired clients +-- ENRA gateways / DHCP / firewall / NAT
                       |                 |
                       +-----------------+
                                         |
                                  Upstream interface
                                         |
                              Existing router / Internet
\`\`\`

ENRA creates a separate IPv4 subnet for Wi-Fi. Additional dedicated Ethernet adapters can be added as separate routed segments, up to 32. Each segment receives its own gateway, subnet and DHCP range.

The Wi-Fi segment defaults to \`10.42.0.1/24\`, with DHCP addresses \`10.42.0.50-10.42.0.200\`. Additional wired segments receive separate subnets. Setup checks for conflicts and selects an available network when a suggested default is already in use.

By default, routed segments can access the upstream network but cannot initiate connections to other ENRA segments. The firewall accepts upstream return traffic for connections initiated by a segment, blocks new connections from the upstream side and checks that each segment uses its assigned IPv4 source range. Inter-segment routing can be enabled by setting \`ALLOW_INTER_SEGMENT_TRAFFIC=true\` in \`/etc/enra/enra.conf\`.

IPv6 forwarding through routed ENRA segments is blocked. ENRA does not currently provide IPv6 routing, DHCPv6 or router advertisements.

Most installations only need the Wi-Fi segment. Add wired segments only when you have extra Ethernet adapters connected to networks that should be managed separately.

## Wi-Fi security

ENRA supports these wireless security profiles:

- **WPA3-Personal:** SAE authentication with mandatory Protected Management Frames.
- **WPA2-Personal:** PSK authentication with AES/CCMP.
- **WPA2/WPA3 transition:** Supports both newer and older client devices.

The wizard recommends WPA2/WPA3 transition mode for compatibility. Choose WPA3-only when every device you plan to connect supports it. A compatible Wi-Fi adapter alone does not guarantee WPA3 support: the driver, firmware, hostapd build and client devices must also support the selected mode.

## Hardware detection and recovery

ENRA identifies configured Wi-Fi and Ethernet adapters by MAC address, allowing it to recover when Linux changes an interface name after a reboot or USB replug.

A persistent link monitor reacts to adapter and cable events. Disconnecting an Ethernet cable does not stop the Wi-Fi access point:

- In bridge mode, the access point and bridge remain available, but clients lose access to the upstream LAN until the cable is restored.
- In routed mode, local Wi-Fi and DHCP remain available, but clients cannot reach the upstream network until it returns.

If the configured Wi-Fi adapter is missing, ENRA defers services that require the access point instead of allowing unrelated services to fail. It only adopts a replacement automatically when exactly one suitable AP-capable adapter is available. If the choice is ambiguous, run \`sudo enra setup\` to select the adapter.

In routed mode, ENRA can automatically add eligible dedicated Ethernet adapters as isolated segments. This is enabled by default and can be disabled with \`AUTO_ADD_INTERFACES=false\` in \`/etc/enra/enra.conf\`. Adapters with an existing global IP address, default route, bridge/master assignment or explicit ifupdown configuration are skipped. Automatic segment integration is disabled in bridge mode because silently bridging an unknown adapter could join unrelated networks.

## Driver handling

ENRA uses the driver already provided by Linux when it exposes a usable wireless interface. It does not replace a working driver.

For USB ID \`0bda:0811\`, when no wireless interface is available, setup can attempt the in-kernel \`rtw88_8821au\` driver and offer a targeted RTL8821AU DKMS fallback. This is a specific recovery path, not a universal driver installer. For other adapters, install the correct driver and firmware through your distribution, verify that the adapter appears with \`iw dev\`, then run \`sudo enra setup\` again.

The RTL8821AU maintainers recommend using an in-kernel driver where available. See the [upstream driver project](https://github.com/morrownr/8821au-20210708) and its [supported USB device IDs](https://github.com/morrownr/8821au-20210708/blob/main/supported-device-IDs) before using an external driver.

## ENRA commands

The installer places the \`enra\` command and updater in \`/usr/local/sbin\`.

| Command | Purpose |
|---|---|
| \`sudo enra setup\` | Run the interactive setup wizard. |
| \`sudo enra status\` | Show ENRA configuration and service health. |
| \`sudo enra /validate\` | Check configuration, interfaces, firewall and services. |
| \`sudo enra preflight\` | Check whether required Wi-Fi hardware is available. |
| \`sudo enra reconcile\` | Reconcile services with currently connected hardware. |
| \`sudo enra logs\` | Show ENRA service logs. |
| \`sudo enra /config\` | Edit the main configuration. |
| \`sudo enra update\` | Download and install the latest version from GitHub. |
| \`sudo enra remove-segment <interface>\` | Remove a managed routed Ethernet segment. |

Lifecycle commands:

| Command | Effect |
|---|---|
| \`sudo enra start\` | Start ENRA for the current session. |
| \`sudo enra stop\` | Stop ENRA for the current session without changing boot startup. |
| \`sudo enra enable\` | Enable boot startup and start ENRA. |
| \`sudo enra disable\` | Stop services and disable boot and hotplug startup, while keeping the configuration. |
| \`sudo enra uninstall\` | Ask for confirmation, then remove ENRA services, configuration and installed commands. |

A separately installed Wi-Fi DKMS driver is not removed by \`sudo enra uninstall\`.

## Diagnostics

Start with these commands when something does not work:

\`\`\`bash
sudo enra status
sudo enra /validate
sudo enra logs
\`\`\`

Use \`enra status\` to inspect ENRA-owned services, network addresses, wireless mode, startup state and recent logs. Use \`enra /validate\` for blocking configuration or service checks. Use \`enra logs\` to inspect service output.

ENRA manages its own systemd units, including \`enra-devices.service\`, \`enra-link-monitor.service\`, \`enra-network.service\`, \`enra-ap.service\` and \`enra-hotplug-scan.service\`. Routed mode also uses \`enra-dnsmasq.service\`. The distribution's \`hostapd.service\` or \`dnsmasq.service\` is not the ENRA service entry point; do not unmask or start those distribution units to operate ENRA.

Common checks:

- **No Wi-Fi adapter appears:** Check that Linux detects the adapter, install its driver and firmware, and verify it with \`iw dev\`. The driver must support AP mode.
- **A wired adapter is missing:** Check that the operating system or virtual machine detects it. For a VM, connect the virtual network adapter or pass the USB adapter through to the guest.
- **Bridge clients do not receive an address:** Confirm that the bridge port is connected to the intended LAN and that its upstream router provides DHCP.
- **Routed clients have no internet:** Check the selected upstream interface and its connection, then inspect \`sudo enra status\` and \`sudo enra logs\`.

## Configuration and limitations

The main configuration is stored in \`/etc/enra/enra.conf\`. Hostapd credentials and routed DHCP/DNS settings are stored separately under \`/etc/enra\`, with root-only permissions. Use \`sudo enra /config\` to edit the main configuration; edits are syntax-checked and backed up.

Important defaults:

- Automatic hardware link bring-up is enabled with \`AUTO_UP_INTERFACES=true\`.
- Automatic routed Ethernet segment integration is enabled with \`AUTO_ADD_INTERFACES=true\`.
- Inter-segment communication is disabled with \`ALLOW_INTER_SEGMENT_TRAFFIC=false\`.
- Automatic Wi-Fi discovery selects an adapter only when a single AP-capable interface is unambiguous.

ENRA does not currently implement VLAN management, 802.1X/RADIUS, captive portals, mesh networking, multi-AP roaming, per-client isolation or automatic channel selection. Review the network-mode behavior before connecting untrusted devices. In particular, bridge mode follows the upstream LAN's trust and firewall policy, while routed mode currently provides IPv4-only routing.

## Development and testing

ENRA is an early release. GitHub Actions checks Bash syntax, ShellCheck, setup behavior, firewall policy, packet forwarding in Linux network namespaces and kernel link-event delivery using virtual Ethernet devices.

These automated tests cover important routing and recovery behavior, but they do not emulate physical Wi-Fi radios, chipset/driver compatibility, hostapd radio behavior or every DHCP client. Not every supported distribution, kernel, adapter, security mode or topology has been physically tested.

When reporting an issue, include your Linux distribution and version, kernel version, Wi-Fi chipset or USB ID, driver, selected network mode and relevant output from \`sudo enra status\` and \`sudo enra logs\`.
