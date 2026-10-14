# 💾 NAS Setup - DXP4800 Plus, Dual RAID Pools, NFS

> Configuring the UGREEN DXP4800 Plus NAS with two purpose-built RAID pools and NFS network mounts.

---

## Overview

The DXP4800 Plus runs UGOS Pro and hosts **all** long-term storage. The K10 mounts two NFS shares, and Docker containers treat them as local storage.

---

## Dual RAID Pools - Different Data, Different Strategies

### Pool 1: Photos - RAID 1 (Mirror)

| Detail | Value |
|---|---|
| Drives | 2× 4TB HDD (Bay 3 + 4) |
| RAID Level | RAID 1 - identical data on both drives |
| Usable | 4TB |
| Shared Folder | `photos` (exported as `/volume1/photos`) |
| NFS Mount | `/mnt/nas/photos` |

**Why RAID 1?** Photos are irreplaceable. Both drives hold identical copies. If one dies, the NAS keeps serving from the survivor and rebuilds automatically when the failed drive is replaced.

This pool was built first, before the media drives arrived, because Immich needed it immediately.

### Pool 2: Media - RAID 0 (Stripe)

| Detail | Value |
|---|---|
| Drives | 2× 12TB HDD (Bay 1 + 2) |
| RAID Level | RAID 0 - data split across both drives |
| Usable | 24TB |
| Shared Folder | `data` (exported as `/volume2/data`) |
| NFS Mount | `/mnt/nas/data` |

**Why RAID 0?** The media library is replaceable, so this pool prioritises capacity and throughput: the full 24TB instead of the 12TB RAID 1 would give. The trade-off is explicit: if either drive fails, the pool is lost. It is not backed up, and that is a documented decision rather than an oversight.

```
RAID 1 (Photos):                    RAID 0 (Media):
     Data ──▶ Drive A (4TB)              Data ──▶ [Drive A] [Drive B]
          └──▶ Drive B (4TB)             Split across both = 24TB usable
          exact mirror                   Full speed, full capacity
```

> 📷 *[RAID 1 Pool](../assets/screenshots/ugos-raid1-pool.png)*
>
> 📷 *[Both Pools](../assets/screenshots/ugos-raid0-pool.png)*

---

## RAID Is NOT a Backup

RAID protects against **hardware failure** only. It does NOT protect against accidental deletion (deleted from one drive = deleted from both), ransomware, file corruption, or physical disaster. The nightly rsync to an external drive provides the second layer, and Uptime Kuma monitoring the third. Full analysis and step-by-step recovery procedures are in [Backup & Disaster Recovery](backup-disaster-recovery.md).

---

## NFS Configuration

**NFS (Network File System)** lets the K10 mount NAS folders over the network. Chosen over SMB for lower overhead on Linux-to-Linux transfers and native Linux ownership and permissions.

### Enable NFS in UGOS Pro
Control Panel → File Services → NFS → **On** → Apply

### NFS Permissions (per share)
- Hostname/IP: `*`
- Permission: **Read/Write**
- Squash: **No mapping**

> **Known improvement:** `*` allows any device on the LAN to mount the shares. Restricting each export to the K10's IP (`192.168.1.101`) is on the improvements list.

---

## Mounting on the K10

### Finding the real export path

UGREEN exports shares by **volume path**, not by share name. Mounting `192.168.1.100:/photos` fails. Ask the NAS what it actually exports:

```bash
showmount -e 192.168.1.100
# /volume1/photos *
```

> 📷 *[Photos share mounted on the K10](../assets/screenshots/nfs-mount-photos.png)*

### `/etc/fstab` entries

```
# NAS shares (NFS)
192.168.1.100:/volume1/photos  /mnt/nas/photos  nfs  defaults,_netdev  0  0
192.168.1.100:/volume2/data    /mnt/nas/data    nfs  defaults,_netdev  0  0

# External backup drive (USB 3.0)
UUID=your-drive-uuid   /mnt/backup      ext4 defaults,nofail  0  2
```

`_netdev` tells Linux to wait for the network before mounting, which prevents boot failures if the NAS takes a moment to respond. `nofail` on the backup drive lets the server boot even if the USB drive is unplugged.

A sanitised version of this fstab is in [`config/fstab.example`](../config/fstab.example).

### Verify

```bash
df -h | grep nas
ls /mnt/nas/
```

> 📷 *[Both NAS shares mounted on the K10](../assets/screenshots/nfs-both-mounts.png)*

---

## Media Folder Structure

```
/data/
└── media/
    ├── tv/         ← Sonarr library
    ├── movies/     ← Radarr library
    ├── anime/      ← Sonarr Anime library
    └── music/
```

---

*[← Photo Backup](photo-backup.md) · [Back to README](../README.md)*
