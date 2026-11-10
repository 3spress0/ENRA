# ENRA

**espress0's Network Routing Architecture**

ENRA is a configurable Linux access-point and network-edge utility built around hostapd, Linux networking and systemd. It adapts to different Linux distributions, wireless adapters, radio settings and network topologies.

## Features

- Interactive setup with wireless hardware and interface discovery.
- Layer 2 bridge or routed/NAT access-point modes.
- WPA3-Personal (SAE), WPA2-Personal and WPA2/WPA3 transition security profiles.
- Configurable SSID, regulatory country, radio band, channel and upstream interface.
- Uses an existing kernel driver where available; it does not assume every adapter is Realtek.
- Optional RTL8821AU DKMS installation when USB ID **0bda:0811** is detected and no wireless interface exists.
- systemd services for startup and recovery.
- Credentials stored in root-only files under **/etc/enra**.

## Supported platforms

ENRA targets systemd-based Linux distributions using these package families:

| Package family | Distribution families |
|---|---|
| APT | Debian, Ubuntu and derivatives |
| DNF | Fedora, RHEL, Rocky Linux, AlmaLinux and derivatives |
| Pacman | Arch Linux, Manjaro, EndeavourOS and derivatives |
| Zypper | openSUSE |

Package-manager support does not mean every release or kernel has been tested. The wireless chipset must have a working Linux driver that exposes AP mode through nl80211. WPA3 also requires compatible hostapd, driver, firmware and client support.

Non-systemd distributions, OpenWrt, BSD, Windows, macOS, and distributions without one of the package families above are not currently supported by this installer.

## Network modes

### Bridge mode

Wireless clients join an existing Ethernet LAN. The upstream router remains responsible for DHCP, DNS, routing, NAT and firewall policy. Use this mode when ENRA is an access point behind OPNsense or another router.

~~~text
Wi-Fi clients
     |
   hostapd
     |
  br-enra
     |
 Ethernet interface
     |
 Existing router / firewall
 (DHCP, DNS, routing and policy)
~~~

The selected Ethernet interface becomes a bridge port and must not retain its own IP address. Choose a dedicated interface that is not carrying the Linux host's management/default route.

### Routed mode

ENRA creates a separate IPv4 subnet on the Wi-Fi interface. It configures a gateway address, dnsmasq for DHCP/DNS forwarding, IP forwarding and nftables masquerading through an upstream interface.

~~~text
Wi-Fi clients
     |
   hostapd
     |
  AP subnet
     |
 dnsmasq + nftables
     |
 Upstream interface
     |
 Existing router / Internet
~~~

Defaults are **10.42.0.1/24**, DHCP **10.42.0.50-10.42.0.200**, and upstream DNS **1.1.1.1**. Change these during setup. Confirm that the AP subnet does not overlap with upstream LAN or VPN routes.

## Wireless security

- **WPA3-Personal:** SAE with mandatory Protected Management Frames (PMF).
- **WPA2-Personal:** PSK with AES/CCMP.
- **Transition mode:** WPA2-PSK and WPA3-SAE together for older clients.

WPA3 is the default. Linux alone does not guarantee WPA3 AP support. The adapter driver, firmware, hostapd build and clients must all support the selected mode. ENRA checks AP mode; service logs show hostapd errors.

## Installation

~~~bash
git clone https://github.com/3spress0/ENRA.git
cd ENRA
sudo ./enra.sh setup
~~~

Setup installs hostapd and wireless tools using the detected package manager. It discovers wireless interfaces, checks that the selected interface advertises AP mode, and asks for topology, interfaces, radio settings and security profile.

### Existing Debian + RTL8821AU + OPNsense setup

Choose:

- Network mode: **bridge**
- Wi-Fi adapter: the Realtek USB adapter's wireless interface
- Wired bridge port: the Debian VM interface connected to the same VMware LAN Segment as the OPNsense LAN
- Country: **NL**
- Band: **2.4 GHz**
- Channel: **6**
- Security: **WPA3-Personal**

Do not select the Debian VMware NAT interface as the bridge port. In bridge mode, OPNsense provides DHCP and network policy for the LAN Segment.

### Driver handling

ENRA uses an existing wireless interface and its kernel driver when one is available. It does not replace a working driver.

If no wireless interface exists but USB ID **0bda:0811** is detected, setup tries the in-kernel **rtw88_8821au** module and then offers the out-of-tree RTL8821AU driver using DKMS. This is a targeted fallback, not a universal driver installer. For other adapters, install the correct driver and firmware through your distribution, verify the interface with **iw dev**, and rerun ENRA.

The RTL8821AU maintainers recommend an in-kernel driver where available on modern kernels. See the [upstream README](https://github.com/morrownr/8821au-20210708) and [supported USB IDs](https://github.com/morrownr/8821au-20210708/blob/main/supported-device-IDs) before using the external driver.

## Commands

After setup, the command is installed as **/usr/local/sbin/enra**:

~~~bash
sudo enra status
sudo enra start
sudo enra stop
sudo enra logs
~~~

ENRA uses **enra-network.service** and **enra-ap.service**. Routed mode also uses **enra-dnsmasq.service**. Services are enabled during setup and start on boot.

## Configuration and limitations

- Main configuration: **/etc/enra/enra.conf**.
- hostapd credentials: **/etc/enra/hostapd.conf** (root-only).
- Routed DHCP/DNS configuration: **/etc/enra/dnsmasq.conf** (root-only).
- Configures 2.4 GHz and 5 GHz hostapd profiles. Actual channels depend on country, adapter and driver.
- Routed mode currently provides IPv4 DHCP and NAT. IPv6 forwarding/firewalling is not configured.
- VLANs, 802.1X/RADIUS, captive portals, mesh, multi-AP roaming, per-client isolation and automatic channel selection are not implemented.
- Bridge mode exposes the LAN according to the upstream router's policy; it does not create a guest-network security boundary.
- Routed mode adds an nftables forward chain and NAT rules for the ENRA AP subnet. Review existing firewall policies before enabling it.
- Selected interfaces should not simultaneously be managed by another network manager or DHCP client. Check NetworkManager, systemd-networkd and ifupdown configuration before setup.

## Development status

ENRA is an early release. It has not been tested across all listed package families, kernels, adapters, security modes or network topologies. Issue reports should include distribution, kernel version, adapter chipset/USB ID, driver, network mode and relevant service logs.
