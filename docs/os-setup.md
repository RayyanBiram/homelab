# 🐧 OS Setup - Ubuntu Server 24.04

> Installing and configuring the K10's operating system, network, remote access, GUI, and VPN.

---

## Ubuntu Server Installation

Ubuntu Server 24.04 LTS was chosen because:

- **Minimal footprint** - no GUI by default, maximising RAM for containers
- **Large community** - extensive troubleshooting resources
- **Beginner Friendly** - Ubuntu is considered an excellent starter tool for those new to Linux

### Installation Steps

1. Downloaded Ubuntu Server 24.04 ISO, flashed to USB with Balena Etcher
2. Installed on the K10 - **OpenSSH Server enabled during install**
3. Set username: `mediaserver`, hostname: `k10`

---

## Static IP Configuration (Netplan)

A static IP ensures the K10 is always at the same address - critical because all Docker configs, NFS mounts, and bookmarks reference it by IP.

```yaml
# /etc/netplan/00-installer-config.yaml
network:
  version: 2
  ethernets:
    enp3s0:
      addresses:
        - 192.168.1.101/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
      dhcp4: false
```

Applied with `sudo netplan apply`.

---

## SSH Access

After confirming SSH works, the monitor and keyboard were permanently unplugged, and plugged back into the main PC. All remaining work is done remotely via SSH and browser.

```bash
ssh mediaserver@192.168.1.101
```

> 📷 *[SSH Connected Via Main PC](../assets/screenshots/ssh-connected.png)*

---

## XFCE Desktop (Lightweight GUI)

| Desktop | Idle RAM |
|---|---|
| GNOME (default) | ~1.5GB |
| **XFCE** | ~300MB |

XFCE was chosen for tasks that benefit from a visual interface — browsing the NAS web UI, taking screenshots for documentation, and occasional troubleshooting. Most configurations were done via SSH, but XFCE was another option at hand.

```bash
sudo apt install -y xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
sudo systemctl enable lightdm
sudo systemctl set-default graphical.target
```

---

## xRDP — Remote Desktop

Exposes XFCE over RDP (port 3389) — connect from Windows via 'remote desktop connection' app or any standard RDP client.

```bash
sudo apt install -y xrdp
echo xfce4-session > ~/.xsession
sudo bash -c 'echo "startxfce4" > /etc/xrdp/startwm.sh'
sudo ufw allow 3389/tcp && sudo ufw allow 22/tcp && sudo ufw enable
sudo systemctl enable xrdp && sudo systemctl start xrdp
```

> 📷 *[XFCE + xRDP Remote Desktop](../assets/screenshots/xfce-remote-desktop.png)*

---

## Tailscale — Secure Remote Access

Tailscale creates an encrypted VPN mesh between devices. With subnet routing enabled, all home services (including the NAS UI at 192.168.1.100) are reachable from anywhere — no router port forwarding required.

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --advertise-routes=192.168.1.0/24 --accept-dns=false
tailscale ip -4
```

Subnet routes must be approved in the Tailscale admin dashboard after install.

> 📷 *[Tailscale Dashboard](../assets/screenshots/tailscale-dashboard.png)*

---

## Firewall (UFW)

```bash
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 3389/tcp    # xRDP
sudo ufw enable
```

Docker container ports are managed by Docker's own networking — UFW rules are not needed for app ports on the `medianet` bridge.

---

*[← Back to README](../README.md) · [Docker Setup →](docker-setup.md)*
