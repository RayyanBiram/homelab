# 🖥️ Hardware

> Physical devices, specs, and how they're connected.

---

## Devices

### GMKtec K10 — Media Server

| Spec | Detail |
|---|---|
| **CPU** | Intel® i9-13900HK (14 cores, 20 threads, up to 5.4GHz) |
| **RAM** | 16GB DDR5 5200MHz |
| **Storage** | 1TB NVMe SSD (OS + Docker configs only) |
| **GPU** | Intel® Iris® Xe Graphics (Intel Quick Sync — hardware transcoding for Plex) |
| **Network** | 2.5GbE ethernet |
| **OS** | Ubuntu Server 24.04 LTS |
| **Role** | Runs all 23 Docker containers 24/7 |
| **Power** | ~15W idle — fanless, silent operation |

**Why the K10?** The i9-13900HK provides significant headroom for Plex hardware transcoding (10+ simultaneous streams via Intel Quick Sync) and Immich machine learning, while idling at only ~15W. Fanless design means zero noise.

> 📷 *[GMKtec K10 NucBox Mini PC](../assets/screenshots/k10-hardware.png)*

---

### UGREEN DXP4800 Plus — NAS

| Spec | Detail |
|---|---|
| **CPU** | Intel Pentium Gold 8505 processor (5 cores, 6 threads, up to 4.4 GHz) |
| **RAM** | 8GB DDR5 4800MHz (expandable to 64GB) |
| **Drive Bays** | 4x 3.5"/2.5" SATA HDD/SSD bays (all 4 populated) |
| **OS** | UGOS Pro (UGREEN's Linux-based NAS OS) |
| **Network** | 10GbE + 2.5GbE ethernet |
| **Role** | Primary storage — dual RAID pools serving NFS to the K10 |

---

### Storage — Dual RAID Pools

| Pool | Drives | RAID Level | Usable | Purpose | Risk Tolerance |
|---|---|---|---|---|---|
| **Photos** | 2× 4TB (Bay 3+4) | RAID 1 (mirror) | 4TB | Immich photos — **irreplaceable** | One drive can fail |
| **Media** | 2× 12TB (Bay 1+2) | RAID 0 (stripe) | 24TB | Media library — speed + capacity priority | No redundancy |

**Why two different RAID levels?** Photos are irreplaceable personal data — RAID 1 ensures one drive can die with zero loss. The media pool prioritises maximum capacity and read/write speed, so RAID 0 is used. Full rationale and risk analysis documented in [Backup & Disaster Recovery](backup-disaster-recovery.md).

> 📷 *[Raid 1 Pool](../assets/screenshots/ugos-raid1-pool.png)*
> 
> 📷 *[Raid 0 Pool](../assets/screenshots/ugos-raid0-pool.png)*

---

### Backup — WD Elements 5TB External HDD

| Detail | Value |
|---|---|
| **Capacity** | 5TB |
| **Connection** | USB 3.0 to K10 |
| **Filesystem** | ext4 (reformatted from NTFS after iCloud transfer) |
| **Mount** | `/mnt/backup` via fstab with `nofail` |
| **Schedule** | Nightly 3am via cron + rsync |
| **Backed up** | Immich photos (~4TB) + Docker config folders |
| **Not backed up** | Plex library cache (regenerable), Immich PostgreSQL (risky mid-write), media files (re-downloadable) |

The WD Elements was first used as an iCloud transfer medium (NTFS, plugged into a Windows PC) to migrate ~400GB of photos to Immich, then reformatted as ext4 and permanently repurposed as the nightly backup drive plugged into the K10. Full lifecycle documented in [Backup & Disaster Recovery](backup-disaster-recovery.md#wd-elements-drive-lifecycle).

---

## Network Setup

All devices connected via **gigabit ethernet** — wired connections provide consistent throughput for NFS file transfers.

| Device | IP Address | Method |
|---|---|---|
| Router | 192.168.1.1 | — |
| GMKtec K10 | 192.168.1.101 | Static (Netplan) |
| DXP4800 Plus NAS | 192.168.1.100 | Static (DHCP reservation) |
| Main PC | 192.168.1.x | DHCP |

> 📷 *[Full Physical Setup (K10 + NAS + Backup Drive)](../assets/screenshots/hardware-setup.png)*

---

*[← Back to README](../README.md)*
