# 💾 NAS Setup — DXP4800 Plus, Dual RAID Pools, NFS

> Configuring the UGREEN DXP4800 Plus NAS with dual purpose-built RAID pools and NFS network mounts.

---

## Overview

The DXP4800 Plus NAS runs UGOS Pro and hosts **all** long-term storage. The K10 mounts two NFS shares — Docker containers treat them as local storage.

---

## Dual RAID Pools — Different Data, Different Strategies

### Pool 2: Photos — RAID 1 (Mirror)

| Detail | Value |
|---|---|
| Drives | 2× 4TB HDD (Bay 3 + 4) |
| RAID Level | RAID 1 — identical data on both drives |
| Usable | 4TB |
| Shared Folder | `photos` |
| NFS Mount | `/mnt/nas/photos` |

**Why RAID 1?** Photos are irreplaceable. Both drives hold identical copies — if one dies, the NAS rebuilds automatically from the survivor.

### Pool 1: Media — RAID 0 (Stripe)

| Detail | Value |
|---|---|
| Drives | 2× 12TB HDD (Bay 1 + 2) |
| RAID Level | RAID 0 — data split across both drives |
| Usable | 24TB |
| Shared Folder | `data` |
| NFS Mount | `/mnt/nas/data` |

**Why RAID 0?** The media pool prioritises maximum capacity and read/write speed. RAID 0 gives full combined capacity — 24TB instead of the 12TB RAID 1 would provide.

```
RAID 1 (Photos):                    RAID 0 (Media):
     Data ──▶ Drive A (4TB)              Data ──▶ [Drive A] [Drive B]
          └──▶ Drive B (4TB)             Split across both = 24TB usable
          exact mirror                   Full speed, full capacity
```

> 📷 *[Raid 1 Pool](../assets/screenshots/ugos-raid1-pool.png)*
> 
> 📷 *[Raid 0 Pool](../assets/screenshots/ugos-raid0-pool.png)*

---

## RAID Is NOT a Backup

RAID protects against **hardware failure** only. It does NOT protect against accidental deletion (deleted from one drive = deleted from both), ransomware, file corruption, or physical disaster. The external HDD rsync backup provides the second safety layer, and Uptime Kuma monitoring provides the third. Full analysis of what RAID protects against vs what it doesn't, along with step-by-step disaster recovery procedures, is documented in [Backup & Disaster Recovery](backup-disaster-recovery.md).

---

## NFS Configuration

**NFS (Network File System)** is used for the K10 to mount NAS folders over the network. Chosen over SMB/Samba for lower overhead on Linux-to-Linux transfers and better sequential read performance.

### Enable NFS in UGOS Pro
Control Panel → File Services → NFS → **On** → Apply

### NFS Permissions (per share)
- Hostname/IP: `*`
- Permission: **Read/Write**
- Squash: **No mapping**

---

## Mounting on the K10

### `/etc/fstab` entries

```
# NAS shares (NFS over gigabit ethernet)
192.168.1.100:/photos  /mnt/nas/photos  nfs  defaults,_netdev  0  0
192.168.1.100:/data    /mnt/nas/data    nfs  defaults,_netdev  0  0

# External backup drive (USB 3.0)
UUID=your-drive-uuid   /mnt/backup      ext4 defaults,nofail  0  2
```

`_netdev` tells Linux to wait for the network before mounting — prevents boot failures if the NAS takes a moment to start. `nofail` on the backup drive prevents boot failures if the USB drive is unplugged.

A sanitised version of this fstab is available in the repo at [`config/fstab.example`](../config/fstab.example).

### Verify

```bash
df -h | grep nas
ls /mnt/nas/
```

> 📷 *[Both NAS NFS Mounted On To K10 (Awaiting arrival of Pool 1 HDD)](../assets/screenshots/nfs-both-mounts.png)*

---

## Media Folder Structure

```
/data/
├── media/
│   ├── tv/         ← Sonarr library
│   ├── movies/     ← Radarr library
│   ├── anime/      ← Sonarr Anime library
│   └── music/
├── usenet/
│   ├── tv/         ← SABnzbd download categories
│   ├── movies/
│   └── anime/
└── torrents/
    ├── tv/         ← qBittorrent download categories
    ├── movies/
    └── anime/
```

Downloads and media share the same `/data` root to enable hardlinks — see [Media Stack](media-stack.md) for details.

---

*[← Photo Backup](photo-backup.md) · [Back to README](../README.md)*
