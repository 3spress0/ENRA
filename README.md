# ENRA

**espress0's Network Routing Architecture**

ENRA is a configurable Linux access-point and network-edge utility built around hostapd, nl80211, Linux networking and systemd. It supports multiple package families, wireless adapters with Linux AP-mode support, radio settings, security profiles and two common network topologies. Adapter driver installation is deliberately separate from AP configuration: ENRA will not guess and replace arbitrary third-party drivers.

## TL;DR - Quickstart

```bash
git clone https://github.com/3spress0/ENRA.git
cd ENRA
sudo ./enra.sh setup
```

Setup is interactive. Choose **bridge** when an existing router handles DHCP and firewalling, or **routed** when ENRA should provide multiple isolated IPv4 segments with DHCP and NAT. WPA3-Personal is the default, but requires compatible Wi-Fi hardware, drivers, firmware and clients.

After setup:

```bash
sudo enra status
```

## Features

- Interactive setup with wireless hardware and interface discovery.
- Layer 2 bridge mode or multi-segment routed/NAT mode.
- Modular routed topology: one upstream interface, one Wi-Fi segment and up to 32 additional Ethernet segments.
- Independent gateway, IPv4 subnet and DHCP pool for every routed segment.
- Firewall isolation between routed segments, with shared upstream NAT and established return traffic.
- WPA3-Personal (SAE), WPA2-Personal and WPA2/WPA3 transition security profiles.
- Configurable SSID, regulatory country, radio band, channel and upstream interface.
- Uses an existing kernel driver where available; it does not assume every adapter is Realtek.
- Optional RTL8821AU DKMS installation when USB ID **0bda:0811** is detected and no wireless interface exists.
- Graceful warning and exit when no wireless interface is available; base dependencies remain installed.
- Kernel-header fallback for DKMS builds. On Debian, if headers for the running kernel are unavailable, ENRA installs the current kernel and matching headers and asks for a reboot before continuing.
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

ENRA creates independent IPv4 subnets on the Wi-Fi interface and any number of dedicated Ethernet interfaces (up to 32 additional wired segments). Every segment has its own gateway address, subnet and DHCP pool. One dnsmasq instance serves all segment interfaces, while nftables isolates segments from each other and masquerades their traffic through the shared upstream interface.

~~~text
                      +-- Wi-Fi AP ------- 10.42.0.0/24
                      |
Clients -- segments --+-- Ethernet LAN 1 -- 10.43.0.0/24
                      |
                      +-- Ethernet LAN 2 -- 10.44.0.0/24
                              |
                    dnsmasq + nftables
                              |
                       Shared upstream
                              |
                     Existing router / Internet
~~~

The Wi-Fi segment defaults to **10.42.0.1/24** with DHCP **10.42.0.50-10.42.0.200**. Additional Ethernet segments receive separate defaults (10.43.0.1/24, 10.44.0.1/24, and so on). These are suggestions only; setup lets you choose every gateway, prefix and DHCP range. Upstream DNS defaults to **1.1.1.1**. ENRA rejects overlapping segment subnets and subnets that conflict with existing routes. Each segment can reach the upstream interface, but cannot initiate connections to another ENRA segment. Unsolicited inbound connections from upstream are blocked; established return traffic is allowed.

## Wireless security

- **WPA3-Personal:** SAE with mandatory Protected Management Frames (PMF).
- **WPA2-Personal:** PSK with AES/CCMP.
- **Transition mode:** WPA2-PSK and WPA3-SAE together for older clients.

WPA3 is the default. Linux alone does not guarantee WPA3 AP support. The adapter driver, firmware, hostapd build and clients must all support the selected mode. ENRA checks AP mode; service logs show hostapd errors.

## Setup behavior

Setup detects the package manager, installs hostapd and wireless tools, discovers wireless interfaces and verifies AP mode. Routed mode asks for one upstream interface, the Wi-Fi segment settings and a number of additional dedicated Ethernet segments. Each Ethernet segment is configured interactively with its own interface, gateway, subnet and DHCP range. ENRA marks all selected downstream interfaces unmanaged in NetworkManager and systemd-networkd where those services are active. If ifupdown has an explicit stanza for a bridge port, setup stops rather than silently rewriting it. If no wireless interface is detected, setup prints a warning and exits without configuring services; connect the adapter/install its driver and rerun setup.

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

If no wireless interface exists but USB ID **0bda:0811** is detected, setup installs the relevant firmware, tries the in-kernel **rtw88_8821au** module and then offers the out-of-tree RTL8821AU driver using DKMS. For DKMS, ENRA first attempts to install headers matching the running kernel. On Debian, if those headers are no longer available, it installs the current kernel and matching headers, pauses setup and asks you to reboot; rerun setup after reboot to build the driver. This is a targeted fallback, not a universal driver installer. For other adapters, install the correct driver and firmware through your distribution, verify the interface with **iw dev**, and rerun ENRA.

The RTL8821AU maintainers recommend an in-kernel driver where available on modern kernels. See the [upstream README](https://github.com/morrownr/8821au-20210708) and [supported USB IDs](https://github.com/morrownr/8821au-20210708/blob/main/supported-device-IDs) before using the external driver.

## Commands

After setup, the command is installed as **/usr/local/sbin/enra**:

~~~bash
sudo enra status
sudo enra /validate
sudo enra start
sudo enra stop
sudo enra logs
~~~

Use **`enra status`** to inspect the ENRA-owned service units, startup state, network addresses, wireless mode and recent logs. Checking `systemctl status hostapd` or `systemctl status dnsmasq` does not show ENRA service health.
Use **`enra /validate`** to run read-only checks against the saved configuration, required commands, wireless AP capability/state, routed-mode dnsmasq configuration, gateway address, IPv4 forwarding, nftables table and ENRA-managed systemd services. It returns a non-zero exit status when a blocking check fails. The shorter alias **`enra validate`** is also accepted.

ENRA uses its own systemd units: **enra-network.service** and **enra-ap.service**. Routed mode also uses **enra-dnsmasq.service**. Services are enabled during setup and start on boot. The installer starts these units directly and does not depend on the distribution-provided **hostapd.service** or **dnsmasq.service**. On Debian, **hostapd.service** may be masked by the package and **dnsmasq-base** may not provide a **dnsmasq.service** unit; neither condition prevents ENRA from working. Do not unmask or start the distribution units to operate ENRA.

## Configuration and limitations

- Main configuration: **/etc/enra/enra.conf**.
- hostapd credentials: **/etc/enra/hostapd.conf** (root-only).
- Routed DHCP/DNS configuration: **/etc/enra/dnsmasq.conf** (root-only). ENRA intentionally stores these files under `/etc/enra`; it does not use `/etc/hostapd` or `/etc/dnsmasq.d`.
- Configures 2.4 GHz and 5 GHz hostapd profiles. Actual channels depend on country, adapter and driver.
- Routed mode provides IPv4 DHCP and NAT for the Wi-Fi segment and up to 32 additional dedicated Ethernet segments. IPv6 forwarding/firewalling is not configured.
- Additional routed Ethernet interfaces must be dedicated, available in the Linux system, not carry the default route and not have an unrelated global IP configuration. In a VM, attach each virtual NIC to the intended VMware LAN Segment before running setup.
- VLANs, 802.1X/RADIUS, captive portals, mesh, multi-AP roaming, per-client isolation and automatic channel selection are not implemented.
- Bridge mode exposes the LAN according to the upstream router's policy; it does not create a guest-network security boundary.
- Routed mode adds an ENRA-owned nftables table with forwarding and NAT rules for every configured segment. Segment-to-segment forwarding and unsolicited upstream-to-segment traffic are blocked. Stopping ENRA removes that table and restores the prior IPv4 forwarding setting. Review existing firewall policies before enabling it.
- ENRA marks selected interfaces unmanaged in NetworkManager and systemd-networkd where available. Explicit ifupdown configurations are detected on bridge ports and cause setup to stop. Other third-party network managers or custom scripts must be reviewed manually.

## Development status

ENRA is an early release. CI checks Bash syntax and ShellCheck, but does not emulate Wi-Fi hardware or verify packet forwarding. It has not been tested across every listed package family, kernel, adapter, security mode or topology. Issue reports should include distribution, kernel version, adapter chipset/USB ID, driver, network mode and relevant service logs.
