# ENRA

**espress0's Network Routing Architecture**

ENRA is a Debian-based network infrastructure project. Its initial component turns a Debian virtual machine into a wireless access point bridged to an OPNsense network.

## Architecture

~~~text
                         Internet
                            |
                     VMware NAT (WAN)
                            |
                        OPNsense
                            |
                  Dedicated LAN Segment
                            |
                 Debian VM - ENRA bridge
                            |
                   br-enra (Layer 2)
                      /         \
             VMware NIC       USB Wi-Fi
             (wired port)       hostapd
                                   |
                           Wireless clients
~~~

OPNsense remains the router and firewall. It provides DHCP, routing, NAT and firewall policy. Debian only bridges Ethernet and Wi-Fi at Layer 2; ENRA does not run a DHCP server, enable IP forwarding, or configure NAT.

Keep the Debian VM's VMware NAT adapter separate. The interface selected during setup must be the Debian virtual NIC connected to the same dedicated VMware LAN Segment as the relevant OPNsense LAN interface.

## Current target

- Debian 13 minimal, systemd-based.
- VMware Workstation virtual machine.
- Realtek USB Wi-Fi adapter: **0bda:0811 (RTL8821AU)**.
- hostapd with WPA3-Personal (SAE), AES/CCMP and mandatory Protected Management Frames (PMF).
- SSID default: **espers cool network**.
- Regulatory domain: Netherlands (**NL**).
- 2.4 GHz channel: 6.
- OPNsense owns DHCP, routing, NAT and firewalling.

## Installation

Connect the Realtek USB adapter to the Debian VM using VMware's **Removable Devices** menu, then clone this repository:

~~~bash
git clone https://github.com/3spress0/ENRA.git
cd ENRA
sudo ./enra.sh setup
~~~

The setup is interactive. It installs the required packages and driver, detects the wireless interface, and asks which wired interface connects to the OPNsense LAN Segment.

**Select only the dedicated OPNsense LAN Segment interface. Do not select the VMware NAT interface or the interface carrying Debian's default route.** ENRA rejects interfaces with a default route, a configured global IP address, an ifupdown stanza, or an existing bridge master. Before continuing, confirm that NetworkManager, systemd-networkd, or another DHCP client does not manage the selected interface.

The installer asks for the SSID and WPA3 passphrase. The passphrase is stored in /etc/enra/hostapd.conf, which is readable only by root. The generated configuration is checked with hostapd before services are enabled.

If matching headers for the currently running kernel are unavailable, the installer installs Debian's kernel and header metapackages and stops. Reboot, return to this directory, and run the setup command again.

## Commands

~~~bash
sudo ./enra.sh status
sudo ./enra.sh start
sudo ./enra.sh stop
sudo ./enra.sh logs
~~~

The bridge and access point are installed as **enra-bridge.service** and **enra-ap.service**, and are enabled at boot.

## Driver

The RTL8821AU driver source is obtained from [morrownr/8821au-20210708](https://github.com/morrownr/8821au-20210708). Its supported USB device list includes 0bda:0811; the driver documents hostapd and AP-mode support.

The installer uses the in-kernel rtw88_8821au module when it is available and advertises the adapter ID. Otherwise it builds the upstream 8821au driver with DKMS. For the Debian 13 kernel-header build issue reported upstream, ENRA applies the documented _FW_UNDER_SURVEY to WIFI_UNDER_SURVEY source fix before DKMS compilation. See [upstream issue #202](https://github.com/morrownr/8821au-20210708/issues/202).

## Important network behaviour

- The ENRA bridge has no IP address by design.
- Wireless clients receive their network configuration from OPNsense.
- Debian's other VMware NICs are left unchanged.
- ENRA does not create firewall rules or provide isolation between wireless clients and the OPNsense LAN. Apply the required policy on OPNsense.
- A bridge connects clients to the Layer 2 network attached to the selected VMware LAN Segment. Verify the OPNsense interface and DHCP scope are configured for that same segment.

## Security

Use a unique WPA2 passphrase. The passphrase is stored locally in a root-only hostapd configuration file and must never be committed to this repository.

The initial release uses WPA3-Personal only (SAE). It requires client support for WPA3 and Protected Management Frames. WPA2 compatibility mode is not enabled.
