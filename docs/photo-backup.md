# 📸 Photo Backup - Immich

> Self-hosted Google Photos replacement with automatic iPhone backup, iCloud migration, and external HDD backup.

---

## Overview

Immich is an open-source, self-hosted photo and video backup solution providing:

- Automatic background backup from iPhone over Wi-Fi (and remotely via Cloudflare Tunnel)
- Full-resolution storage with no compression
- Machine learning: face recognition, object detection, smart search
- Timeline view, albums, sharing, and GPS map view
- External access at `https://immich.biram.uk`, protected by Cloudflare Access

All photos are stored on the NAS at `/mnt/nas/photos` (RAID 1 mirrored 4TB pool) and backed up nightly to a 5TB external HDD. The full backup strategy and disaster recovery procedures are documented in [Backup & Disaster Recovery](backup-disaster-recovery.md).

---

## Architecture - 4 Containers

```
┌──────────────────────────────────────────────┐
│           medianet (Docker network)          │
│                                              │
│  ┌──────────────┐     ┌───────────────────┐  │
│  │immich_server │     │    immich_ml      │  │
│  │ Web UI :2283 │     │ Face recognition  │  │
│  │ Upload API   │     │ Object detection  │  │
│  └──────┬───────┘     └───────────────────┘  │
│         │                                    │
│  ┌──────▼────────┐     ┌───────────────────┐ │
│  │immich_postgres│     │   immich_redis    │ │
│  │ Metadata      │     │ Cache & sessions  │ │
│  └───────────────┘     └───────────────────┘ │
└──────────────────────────────────────────────┘
         │
  /mnt/nas/photos  (RAID 1 - 4TB mirrored)
```

> 📷 *[Immich Timeline](../assets/screenshots/immich-timeline.png)*

---

## External Access - immich.biram.uk

Accessible from anywhere via Cloudflare Tunnel. Unlike Seerr (open to household & friends), Immich is locked behind **Cloudflare Access** - visitors must verify via a one-time email code before reaching the login page.

The Immich mobile app bypasses Cloudflare Access by authenticating directly with the API token.

---

## iCloud Migration

The iPhone's iCloud library (~400GB) stores only thumbnails on-device with originals in the cloud. The WD Elements 5TB external HDD is used as the transfer device - it is going to be reformatted and repurposed later as the permanent backup drive.

**Migration path:**

1. **Plug WD Elements into Windows PC** via USB
2. **Download full iCloud library** onto the drive using iCloud for Windows (overnight)
3. **Bulk upload to Immich** via the web UI's folder upload - browse to the drive and select the folder
4. **Verify** photo count matches
5. **Configure the Immich iPhone app** for automatic backup going forward
6. **Downgrade iCloud** to the free 5GB plan
7. **Reformat the WD Elements** as ext4 and plug into the K10 - it becomes the nightly backup drive

The full lifecycle of the WD Elements drive (from iCloud transfer to permanent backup) is documented in [Backup & Disaster Recovery](backup-disaster-recovery.md#wd-elements-drive-lifecycle).

Immich backup is **one-way** - deleting from the iPhone does NOT delete from Immich. Any pictures remaining on the iPhone will be temporary; the NAS is the permanent archive.

---

## Backup Strategy - Three Layers

| Layer | Protects Against | Location |
|---|---|---|
| **RAID 1** (NAS) | Single drive failure | 2 × 4TB mirrored |
| **External HDD** (rsync) | Deletion, corruption, NAS failure | WD Elements 5TB |
| **Uptime Kuma** (monitoring) | Silent failures, unnoticed downtime | HTTP checks every 60s |

The nightly backup script, rsync configuration, cron schedule, and step-by-step disaster recovery procedures for three failure scenarios (single drive, K10 death, NAS pool loss) are fully documented in [Backup & Disaster Recovery](backup-disaster-recovery.md).

---

*[← Media Stack](media-stack.md) · [Back to README](../README.md) · [NAS Setup →](nas-setup.md)*
