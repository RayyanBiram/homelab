<div align="center">

# 🏠 Home Lab

### Self-hosted media server, NAS, photo backup & network services — built from scratch

[![Ubuntu](https://img.shields.io/badge/Ubuntu_Server-24.04_LTS-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![Plex](https://img.shields.io/badge/Plex-Media_Server-E5A00D?style=for-the-badge&logo=plex&logoColor=white)](https://www.plex.tv/)
[![Immich](https://img.shields.io/badge/Immich-Photo_Backup-4250AF?style=for-the-badge&logo=immich&logoColor=white)](https://immich.app/)
[![Cloudflare](https://img.shields.io/badge/Cloudflare-Tunnel-F38020?style=for-the-badge&logo=cloudflare&logoColor=white)](https://www.cloudflare.com/)
[![Status](https://img.shields.io/badge/Status-Active_Build-4ade80?style=for-the-badge)](#-build-diary)

</div>

---

## 📖 Overview

This repository documents the end-to-end design, build, and configuration of a personal home lab. The project covers Linux server administration, containerisation with Docker Compose, NAS configuration with dual RAID pools, NFS network storage, VPN networking, reverse proxy tunnelling via Cloudflare, and automated monitoring and backups.

Built as a practical demonstration of skills relevant to **IT Support, Sysadmin, and DevOps** roles — every decision, command, and configuration is documented here.

> 📓 **[Follow the live build diary →](docs/diary.md)**

---

## 🖥️ Hardware

| Device | Model | Specs | Role |
|---|---|---|---|
| **Media Server** | GMKtec K10 | Intel i9-13900HK, 16GB DDR5, 512GB NVMe | Docker host — runs all containers 24/7 |
| **NAS** | UGREEN DXP4800 Plus | Intel N100, 8GB DDR5, 4× 3.5" bays | Network storage — dual RAID pools |
| **Photos Pool** | 2× 4TB HDD | RAID 1 (mirror) — 4TB usable | Immich photo backup — irreplaceable data |
| **Media Pool** | 2× 12TB HDD | RAID 0 (stripe) — 24TB usable | Media library — max speed and capacity |
| **Backup** | WD Elements 5TB | USB external HDD | iCloud transfer drive, then reformatted as nightly backup |
| **Network** | Gigabit ethernet | All devices wired | Consistent throughput for NFS transfers |

> 📷 **[Hardware photos & specs →](docs/hardware.md)**

---

## 🗺️ Network Architecture

```
                        ┌──────────────────────┐
                        │       Router         │
                        │    192.168.1.1       │
                        └──────────┬───────────┘
                                   │  Gigabit Ethernet
               ┌───────────────────┼────────────────────┐
               │                   │                    │
    ┌──────────▼──────────┐ ┌──────▼──────────┐  ┌──────▼──────────┐
    │    GMKtec K10       │ │ DXP4800 Plus NAS│  │    Main PC      │
    │   192.168.1.101     │ │  192.168.1.100  │  │  192.168.1.x    │
    │                     │ │                 │  └─────────────────┘
    │  Docker Containers  │ │  UGOS Pro       │
    │  on medianet bridge │ │                 │
    │                     │ │  Pool 1 RAID 0  │  ┌─────────────────┐
    │  Media Management:  │ │  /data (24TB)   │  │ Cloudflare CDN  │
    │   Plex, Sonarr,     │ │   └─ media/     │  │ seerr.biram.uk  │
    │   Radarr, Bazarr,   │ │                 │  │ immich.biram.uk │
    │   Seerr             │ │  Pool 2 RAID 1  │  └────────▲────────┘
    │                     │ │  /photos (4TB)  │           │
    │  Infrastructure:    │ │                 │    Cloudflare Tunnel
    │   Portainer,        │ │  NFS mounted:   │   (cloudflared container)
    │   Cloudflared,      │◄────/mnt/nas/data │
    │   AdGuard Home      │ │   /mnt/nas/photo│  ┌─────────────────┐
    │   Uptime Kuma,      │ └─────────────────┘  │ Tailscale VPN   │
    │   Watchtower,       │                      │ Remote access   │
    │   Homarr            │  ┌─────────────────┐ │ from anywhere   │
    │                     │  │ WD Elements 5TB │ └─────────────────┘
    │  Photo Backup:      │  │ /mnt/backup     │
    │Immich (4 containers)│  │ Nightly rsync   │
    │                     │  └─────────────────┘
    │  XFCE + xRDP :3389  │
    └─────────────────────┘
```

---

## 🛠️ Tech Stack

### Infrastructure
| Technology | Purpose |
|---|---|
| **Ubuntu Server 24.04 LTS** | Host OS on the K10 |
| **Docker + Docker Compose** | Container orchestration across a shared bridge network |
| **XFCE + xRDP** | Lightweight remote desktop GUI (300MB RAM vs GNOME's 1.5GB) |
| **NFS (Network File System)** | Mounting NAS shares — containers treat NAS as local storage |
| **UGOS Pro** | NAS operating system managing both RAID pools |
| **RAID 1 + RAID 0** | Mirrored pool for photos, striped pool for media |
| **Tailscale** | Zero-config VPN mesh — secure remote access to all services |
| **Cloudflare Tunnel** | Expose services publicly without opening router ports |

### Applications
| App | Category | Port | Purpose |
|---|---|---|---|
| [Plex](https://www.plex.tv/) | Media Server | 32400 | Streams media with Intel Quick Sync HW transcoding |
| [Sonarr](https://sonarr.tv/) | Media Management | 8989 | TV show library organisation, metadata, and renaming |
| [Sonarr Anime](https://sonarr.tv/) | Media Management | 8990 | Separate instance with anime-specific profiles |
| [Radarr](https://radarr.video/) | Media Management | 7878 | Movie library organisation, metadata, and renaming |
| [Bazarr](https://www.bazarr.media/) | Subtitles | 6767 | Automatic subtitle matching and downloading |
| [Seerr](https://github.com/seerr-team/seerr) | Requests | 5055 | Media request portal for the household |
| [Immich](https://immich.app/) | Photos | 2283 | Self-hosted photo backup with ML face/object recognition |
| Immich ML | Photos | — | Machine learning for face and object detection |
| Redis | Photos | — | Cache layer for Immich |
| PostgreSQL | Photos | — | Immich metadata database |
| [Portainer](https://www.portainer.io/) | Management | 9000 | Docker container management GUI |
| [Cloudflared](https://developers.cloudflare.com/cloudflare-one/) | Tunnel | — | Outbound tunnel to Cloudflare edge network |
| [AdGuard Home](https://adguard.com/adguard-home.html) | DNS | 80 | Network-wide ad blocking and local DNS rewrites |
| [Uptime Kuma](https://github.com/louislam/uptime-kuma) | Monitoring | 3001 | Service health monitoring with push notifications |
| [Watchtower](https://containrrr.dev/watchtower/) | Updates | — | Automated Docker image updates (4am daily) |
| [Homarr](https://homarr.dev/) | Dashboard | 7575 | Unified home lab dashboard |

---

## 📁 Repository Structure

```
homelab/
├── README.md                    ← You are here
├── GITHUB-SETUP.md              ← How to create and publish this repo
├── docs/
│   ├── diary.md                 ← Live build log with dates and screenshots
│   ├── hardware.md              ← Hardware specs and physical setup photos
│   ├── os-setup.md              ← Ubuntu, static IP, SSH, XFCE, xRDP, Tailscale
│   ├── docker-setup.md          ← Docker install, Compose, networking, log rotation
│   ├── media-stack.md           ← Plex, Sonarr, Radarr, Bazarr, Seerr, Cloudflare Tunnel
│   ├── photo-backup.md          ← Immich, iCloud migration, backup strategy
│   └── nas-setup.md             ← Dual RAID pools, NFS, folder structure
├── config/
│   ├── docker-compose.yml       ← Production Compose file (core stack)
│   └── immich.env.example       ← Sanitised Immich environment template
└── assets/
    └── screenshots/             ← App screenshots and hardware photos
```

---

## 🚀 Key Skills Demonstrated

- **Linux server administration** — Ubuntu Server 24.04, Netplan static IP, SSH, UFW firewall, systemd, cron scheduling
- **Containerisation** — Docker Compose orchestrating multiple containers with inter-service API communication on a bridge network
- **Storage & redundancy** — Dual RAID pools (RAID 1 for critical data, RAID 0 for performance), NFS network mounts, fstab persistence
- **Networking** — Static IPs, NFS ACLs, Docker bridge networking, container-name DNS resolution
- **Security** — Cloudflare Access zero-trust policies, credential isolation via `.env` files, VPN networking
- **Reverse proxy & tunnelling** — Cloudflare Tunnel exposing services with automatic HTTPS, no port forwarding
- **Remote access** — Tailscale VPN mesh with subnet routing, xRDP remote desktop
- **Automation** — Media library management, automated subtitle fetching, Docker image auto-updates, nightly rsync backup via cron
- **Monitoring** — Uptime Kuma health checks with push notifications, Portainer container management, AdGuard DNS analytics
- **Backup strategy** — RAID 1 (drive failure) + external HDD rsync (deletion/corruption) — two independent safety layers
- **Documentation** — Architecture diagrams, build diary, reproducible config files, version-controlled with Git

---

## 📓 Build Diary

> 📖 **[Read the full diary →](docs/diary.md)**

---

## 📚 Documentation

| Page | Description |
|---|---|
| [🖥️ Hardware](docs/hardware.md) | Device specs, dual RAID pools, physical setup |
| [🐧 OS Setup](docs/os-setup.md) | Ubuntu Server, static IP, SSH, XFCE/xRDP, Tailscale |
| [🐳 Docker Setup](docs/docker-setup.md) | Docker install, Compose file, networking, log rotation |
| [🎬 Media Stack](docs/media-stack.md) | Plex, library management, Seerr, Cloudflare Tunnel |
| [📸 Photo Backup](docs/photo-backup.md) | Immich, iCloud migration, backup strategy |
| [💾 NAS Setup](docs/nas-setup.md) | Dual RAID pools, NFS, media folder structure |

---

<div align="center">

**Built and documented by Rayyan Biram**
*Ongoing project — check commit history for build progression*

</div>
