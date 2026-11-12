# ENRA

**espress0's Network Routing Architecture**

ENRA is a configurable Linux access-point and network-edge utility built around hostapd, nl80211, Linux networking and systemd. It supports multiple package families, wireless adapters with Linux AP-mode support, radio settings, security profiles and two common network topologies. Adapter driver installation is deliberately separate from AP configuration: ENRA will not guess and replace arbitrary third-party drivers.

## TL;DR - Quickstart

```bash
git clone https://github.com/3spress0/ENRA.git
cd ENRA
sudo ./install.sh
sudo enra setup
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
- Routed firewall policy limits segment traffic to IPv4 upstream access, return traffic for segment-originated connections and explicitly enabled inter-segment communication.
- Per-segment IPv4 source-address checks prevent one segment from spoofing another segment's subnet; all other forwarding to or from ENRA segments is dropped.
- IPv6 forwarding through ENRA routed segments is blocked until ENRA has explicit IPv6 configuration and firewall support.
- WPA3-Personal (SAE), WPA2-Personal and WPA2/WPA3 transition security profiles.
- Configurable SSID, regulatory country, radio band, channel and upstream interface.
- Uses an existing kernel driver where available; it does not assume every adapter is Realtek.
- Optional RTL8821AU DKMS installation when USB ID **0bda:0811** is detected and no wireless interface exists.
- Graceful warning and exit when no wireless interface is available; base dependencies remain installed.
- Kernel-header fallback for DKMS builds. On Debian, if headers for the running kernel are unavailable, ENRA installs the current kernel and matching headers and asks for a reboot before continuing.
- Boot-time discovery and link bring-up for all detected hardware-backed network interfaces.
- Udev hotplug handling and boot-time reconciliation that add eligible Ethernet NICs as isolated routed segments automatically, up to the 32-segment limit.
- Automatic subnet allocation, DHCP configuration, NAT and firewall isolation for newly added routed segments.
- systemd services for device bring-up, hotplug integration, network configuration, access-point startup and recovery.
- Installable **enra** command in **/usr/local/sbin**, plus a GitHub-based updater.
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

The Wi-Fi segment defaults to **10.42.0.1/24** with DHCP **10.42.0.50-10.42.0.200**. Additional Ethernet segments receive separate defaults (10.43.0.1/24, 10.44.0.1/24, and so on). These are suggestions only; setup lets you choose every gateway, prefix and DHCP range. Upstream DNS defaults to **1.1.1.1**. ENRA rejects overlapping segment subnets and subnets that conflict with existing routes. By default, each segment can reach the upstream interface but cannot initiate connections to another ENRA segment. Set **ALLOW_INTER_SEGMENT_TRAFFIC=true** in **/etc/enra/enra.conf** to allow IPv4 routing between all ENRA segments. The firewall accepts upstream-to-segment packets only when conntrack identifies them as replies to connections initiated by a segment. New connections from the upstream interface and forwarding through other interfaces into ENRA segments are blocked. Source addresses on each segment are checked against that segment's configured subnet. IPv6 forwarding through ENRA segments is blocked.

With **AUTO_ADD_INTERFACES=true**, ENRA watches network-device add events and performs a full NIC scan after network startup. In routed mode, a new eligible Ethernet NIC is assigned the first unused **10.60.0.0/24-10.254.255.0/24** subnet, with gateway **.1** and DHCP range **.50-.200**. ENRA persists the segment, updates dnsmasq, and rebuilds its nftables NAT/isolation rules. The feature never claims the configured Wi-Fi or upstream interface. NICs that already have a global IP, carry a default route, belong to another bridge/master, or have an ifupdown stanza are skipped. If a configured NIC is temporarily absent, ENRA preserves its subnet and skips that port until it returns; the same segment is restored when the NIC reappears. Remove permanently retired segments manually through **sudo enra /config**.

Automatic routed integration is intentionally disabled in bridge mode. Additional bridge ports change Layer 2 trust boundaries and must be selected explicitly.

## Wireless security

- **WPA3-Personal:** SAE with mandatory Protected Management Frames (PMF).
- **WPA2-Personal:** PSK with AES/CCMP.
- **Transition mode:** WPA2-PSK and WPA3-SAE together for older clients.

WPA3 is the default. Linux alone does not guarantee WPA3 AP support. The adapter driver, firmware, hostapd build and clients must all support the selected mode. ENRA checks AP mode; service logs show hostapd errors.

## Setup behavior

Setup detects the package manager, installs hostapd and wireless tools, discovers wireless interfaces and verifies AP mode. Routed mode asks for one upstream interface, the Wi-Fi segment settings and a number of additional dedicated Ethernet segments. Each manually selected Ethernet segment is configured with its own interface, gateway, subnet and DHCP range. After the core services start, ENRA scans for other eligible Ethernet NICs. A udev rule also handles NICs connected later. ENRA marks selected downstream interfaces unmanaged in NetworkManager and systemd-networkd where those services are active. If ifupdown has an explicit stanza for a bridge port, setup stops rather than silently rewriting it. If no wireless interface is detected, setup prints a warning and exits without configuring services; connect the adapter/install its driver and rerun setup.

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

Install ENRA from a cloned repository with **sudo ./install.sh**. The installer places the command at **/usr/local/sbin/enra** and the updater at **/usr/local/sbin/enra-update**. You can then use ENRA from your PATH:

~~~bash
sudo enra setup
sudo enra status
sudo enra /validate
sudo enra /config
sudo enra update
sudo enra start
sudo enra stop
sudo enra disable
sudo enra enable
sudo enra uninstall
sudo enra logs
~~~

The installer can also be run directly from GitHub:

~~~bash
curl -fsSL https://raw.githubusercontent.com/3spress0/ENRA/main/install.sh | sudo bash
sudo enra setup
~~~

**Lifecycle commands:** `sudo enra stop` stops ENRA for the current session without changing boot startup. `sudo enra disable` stops services, disables boot startup and removes the hotplug udev rule while retaining configuration. `sudo enra start` starts ENRA for the current session and restores hotplug handling; `sudo enra enable` also enables boot startup. `sudo enra uninstall` asks for confirmation, then removes ENRA services, configuration and installed commands. A separately installed Wi-Fi DKMS driver is not removed.

Use **`enra status`** to inspect the ENRA-owned service units, startup state, network addresses, wireless mode and recent logs. Checking `systemctl status hostapd` or `systemctl status dnsmasq` does not show ENRA service health.
Use **`enra /validate`** to run read-only checks against the saved configuration, required commands, wireless AP capability/state, routed-mode dnsmasq configuration, gateway address, IPv4 forwarding, nftables table and ENRA-managed systemd services. It returns a non-zero exit status when a blocking check fails. The shorter alias **`enra validate`** is also accepted.

ENRA uses its own systemd units: **enra-devices.service**, **enra-network.service**, **enra-ap.service** and **enra-hotplug-scan.service**. Routed mode also uses **enra-dnsmasq.service**. Services are enabled during setup and start on boot. The device service runs after the network managers and udev settle, discovers hardware-backed interfaces under **/sys/class/net**, and sets their link state to UP. The hotplug scan reconciles all current NICs after ENRA networking starts. The **enra-hotplug@.service** template handles later udev add events. The device service excludes loopback and ENRA's bridge. The installer starts these units directly and does not depend on the distribution-provided **hostapd.service** or **dnsmasq.service**. On Debian, **hostapd.service** may be masked by the package and **dnsmasq-base** may not provide a **dnsmasq.service** unit; neither condition prevents ENRA from working. Do not unmask or start the distribution units to operate ENRA.

## Configuration and limitations

- Main configuration: **/etc/enra/enra.conf**. Use **sudo enra /config** to edit it, **sudo enra /config show** to display it, or **sudo enra /config path** to print its path. Edits are syntax-checked and backed up. The generated hostapd and dnsmasq files are separate; rerun setup to rebuild those profiles.
- Automatic interface bring-up is enabled by default with **AUTO_UP_INTERFACES=true**. Set it to **false** to disable link-state changes.
- Automatic routed NIC integration is enabled by default with **AUTO_ADD_INTERFACES=true**. Set it to **false** to disable automatic segment creation. This feature only operates in routed mode.
- Inter-segment communication is disabled by default with **ALLOW_INTER_SEGMENT_TRAFFIC=false**. Set it to **true** to allow routed traffic between all ENRA segments. The setting does not permit new connections from the upstream interface into ENRA segments.
- Change the setting with **sudo enra /config**, then apply it with **sudo enra refresh**. Legacy configuration files without this option default to **false**.
- Put space-separated or comma-separated interface names in **AUTO_UP_EXCLUDE** to keep specific adapters out of automatic bring-up and routed integration.
- Automatic bring-up only changes link state. Automatic segment integration assigns a free /24 subnet, gateway, DHCP range, NAT and firewall policy. It skips NICs with an existing global IP address, a default route, an existing bridge/master, or an ifupdown configuration. NetworkManager and systemd-networkd are marked unmanaged for interfaces ENRA claims.
- hostapd credentials: **/etc/enra/hostapd.conf** (root-only).
- Routed DHCP/DNS configuration: **/etc/enra/dnsmasq.conf** (root-only). ENRA intentionally stores these files under `/etc/enra`; it does not use `/etc/hostapd` or `/etc/dnsmasq.d`.
- Configures 2.4 GHz and 5 GHz hostapd profiles. Actual channels depend on country, adapter and driver.
- Routed mode provides IPv4 DHCP and NAT for the Wi-Fi segment and up to 32 additional dedicated Ethernet segments. New eligible NICs can be added automatically. Temporarily missing NICs retain their saved subnet and are skipped until they return. IPv6 forwarding through ENRA segments is blocked; IPv6 addressing, DHCPv6, router advertisements and IPv6 NAT/routing are not provided.
- Additional routed Ethernet interfaces must be dedicated, available in the Linux system, not carry the default route and not have an unrelated global IP configuration. In a VM, attach each virtual NIC to the intended VMware network before running setup. A VMware LAN Segment is private to VMs connected to that segment; it is not a physical Ethernet port. For a physical LAN, use a bridged VMnet mapped to a separate host NIC or pass a USB Ethernet adapter through to the guest.
- VLANs, 802.1X/RADIUS, captive portals, mesh, multi-AP roaming, per-client isolation and automatic channel selection are not implemented.
- Bridge mode exposes the LAN according to the upstream router's policy; it does not create a guest-network security boundary.
- Routed mode adds an ENRA-owned nftables table with forwarding and NAT rules for every configured segment. Segment traffic is permitted only to the upstream interface, to other ENRA segments when explicitly enabled, and for upstream return packets in the conntrack reply direction. Other forwarding to or from ENRA segment interfaces is dropped; unrelated forwarding through the host is left to other firewall policy. IPv4 source addresses are checked per segment. Stopping ENRA removes that table and restores the prior IPv4 forwarding setting. Review existing firewall policies before enabling it.
- ENRA marks selected interfaces unmanaged in NetworkManager and systemd-networkd where available. The boot-time device service only raises hardware-backed links; it does not override addressing or routing policy. Explicit ifupdown configurations are detected on bridge ports and cause setup to stop. Other third-party network managers or custom scripts must be reviewed manually.

## Development status

ENRA is an early release. CI checks Bash syntax, ShellCheck and the expected firewall-policy rules, but does not emulate Wi-Fi hardware or verify actual packet forwarding. It has not been tested across every listed package family, kernel, adapter, security mode or topology. Issue reports should include distribution, kernel version, adapter chipset/USB ID, driver, network mode and relevant service logs.
