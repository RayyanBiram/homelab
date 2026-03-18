# 🛡️ Backup & Disaster Recovery
 
> Automated nightly backup, three-layer protection strategy, and step-by-step disaster recovery procedures.
 
---
 
## Overview
 
My home lab stores two different types of data — **irreplaceable personal data** (photos, Docker configurations) and **replaceable media** (TV shows, movies, music). The backup strategy treats them differently:
 
- **Photos** are backed up with full redundancy: RAID 1 mirroring on the NAS + nightly rsync to an external HDD. Two independent copies exist at all times.
- **Docker configs** are backed up nightly to the external HDD. These contain hours of configuration work — app settings, API connections, quality profiles, user accounts — that would take significant effort to recreate from scratch.
- **Media files** (Plex library content) are **not backed up**. They're stored on a RAID 0 pool optimised for speed and capacity. If lost, they can be re-downloaded — inconvenient but not catastrophic.
 
The backup runs automatically at 3am every night via a cron job. No manual intervention is required after initial setup.
 
---
 
## What's Backed Up
 
| Data | Location | Backed Up? | Why |
|---|---|---|---|
| **Immich photos & videos** | `/mnt/nas/photos` (NAS RAID 1) | ✅ Yes — nightly rsync | Irreplaceable personal data. Family photos, memories, documents — once lost, gone forever. |
| **Docker config folders** | `~/docker/` (K10 SSD) | ✅ Yes — nightly rsync | Contains every app's settings, databases, API keys, quality profiles, and user accounts. Rebuilding from scratch would take hours of manual reconfiguration. |
| **Plex library cache** | `~/docker/plex/config/Library/` | ❌ Excluded | Plex rebuilds this automatically by re-scanning the media folders. It's large (potentially tens of GB) and fully regenerable — backing it up wastes space and time. |
| **Immich PostgreSQL database** | `~/docker/immich/pgdata/` | ❌ Excluded | The database contains photo metadata (face tags, albums, search index). Immich can rebuild this by re-processing the photo files on the NAS. Backing up the raw database mid-write risks corruption — Immich's own dump tools are safer for this. |
| **Media files** (TV, movies, anime) | `/mnt/nas/data` (NAS RAID 0) | ❌ Not backed up | Replaceable content. The RAID 0 pool is 24TB — no backup drive is large enough, and the content can be re-downloaded. |
| **Docker Compose file** | `~/docker/docker-compose.yml` | ✅ Also on GitHub | The compose file is the blueprint for the entire stack. It's backed up both by rsync (nightly) and by the GitHub repo (version-controlled). |
| **Credential files** (`.env`, `immich.env`) | `~/docker/` | ✅ Yes — nightly rsync | Contains VPN keys, tunnel tokens, database passwords. These are backed up by rsync but never pushed to GitHub. |
 
---
 
## Backup Script (`scripts/backup.sh`)
 
The backup script uses `rsync`, a standard Linux file synchronisation tool. It compares the source and destination, copies only what's changed, and optionally deletes files from the backup that no longer exist in the source.
 
```bash
#!/bin/bash
# ═══════════════════════════════════════════════════════════
#  Nightly Backup Script — runs via cron at 3:00 AM
#  Backs up: Immich photos (NAS) + Docker configs (SSD)
#  Target:   WD Elements 5TB external HDD at /mnt/backup
# ═══════════════════════════════════════════════════════════
 
# ── BACKUP 1: Immich Photos ──────────────────────────────
# Source:  /mnt/nas/photos/  (NAS RAID 1 pool, mounted via NFS)
# Target:  /mnt/backup/photos/  (external HDD)
#
# Flags:
#   -a  = archive mode (preserves permissions, timestamps,
#         symlinks, owner, group — exact copy)
#   -v  = verbose (logs every file copied — useful for
#         reviewing backup.log)
#   --delete = remove files from the backup that no longer
#              exist in the source (keeps backup in sync,
#              prevents it growing forever with deleted files)
#
# The trailing slashes on paths are important:
#   /mnt/nas/photos/  = copy the CONTENTS of the folder
#   /mnt/nas/photos   = copy the folder itself (creates photos/photos/)
 
rsync -av --delete /mnt/nas/photos/ /mnt/backup/photos/
 
 
# ── BACKUP 2: Docker Config Folders ──────────────────────
# Source:  ~/docker/  (K10 local SSD)
# Target:  /mnt/backup/docker-config/  (external HDD)
#
# --exclude flags skip directories that are either:
#   1. Too large and fully regenerable (Plex library cache)
#   2. Risky to copy mid-write (Immich PostgreSQL data)
#
# Everything else IS backed up:
#   - docker-compose.yml (the entire stack definition)
#   - .env and immich.env (all credentials)
#   - sonarr/config, radarr/config, etc. (app databases
#     with API keys, quality profiles, download history)
#   - recyclarr config, adguard config, uptime-kuma data
 
rsync -av --delete ~/docker/ /mnt/backup/docker-config/ \
  --exclude='plex/config/Library' \
  --exclude='immich/pgdata'
```
 
### How rsync works
 
rsync doesn't copy every file every night. On the first run, it copies everything (full backup). On subsequent runs, it compares file sizes and modification timestamps between source and destination — only changed or new files are transferred. This makes nightly backups fast even though the total data set is hundreds of gigabytes.
 
The `--delete` flag is a deliberate choice: if you delete a photo from Immich, it should also be removed from the backup on the next run. This prevents the backup from accumulating orphaned files indefinitely. The trade-off is that accidental deletions are also synced — the backup is a mirror, not a historical archive. For point-in-time recovery (e.g. "I deleted a photo 3 days ago and want it back"), a future improvement would be adding snapshot-based or versioned backups.
 
---
 
## Schedule & Logging
 
The backup runs automatically via **cron**, Linux's built-in task scheduler. No manual intervention is needed after the initial setup.
 
### Cron Configuration
 
```bash
# Edit the crontab (the list of scheduled tasks for your user)
crontab -e
 
# Add this line at the bottom:
# ┌─── minute (0)
# │ ┌─── hour (3 = 3:00 AM)
# │ │ ┌─── day of month (* = every day)
# │ │ │ ┌─── month (* = every month)
# │ │ │ │ ┌─── day of week (* = every day)
# │ │ │ │ │
  0 3 * * * /home/mediaserver/backup.sh >> /home/mediaserver/backup.log 2>&1
```
 
### Why 3:00 AM?
 
- **No active usage** — nobody is streaming Plex, uploading photos, or managing containers at 3am. This minimises the chance of backing up files mid-write.
- **After Watchtower - Currently disabled - API version incompatibility with Docker 25+** — Watchtower runs at 4am by default. Running backups before updates means you have a clean backup to restore if an update breaks something.
- **Network idle** — no competition for NFS bandwidth between the NAS and K10.
 
### Log Output
 
All rsync output (files copied, errors, transfer stats) is added to `~/backup.log`:
 
```bash
# View the last 50 lines of backup history
tail -50 ~/backup.log
 
# Check if last night's backup ran successfully
# Look for the rsync summary at the end (total bytes, speedup ratio)
tail -20 ~/backup.log
 
# Check the file size — if it's growing, backups are running
ls -lh ~/backup.log
```
 
The `2>&1` at the end of the cron line redirects both standard output (file list) and standard error (any error messages) into the same log file. Without this, errors would be silently lost.
 
---
 
## RAID Is NOT a Backup
 
This is one of the most commonly misunderstood concepts in data storage. RAID and backups solve **completely different problems**.
 
### What RAID protects against
 
RAID protects against **hardware failure** — specifically, a hard drive dying. In a RAID 1 (mirror) array, both drives hold identical data. If one drive fails, the NAS continues operating on the surviving drive and automatically rebuilds when you insert a replacement. **Zero data loss, zero downtime.**
 
### What RAID does NOT protect against
 
| Threat | What happens with RAID only | What happens with RAID + backup |
|---|---|---|
| **Accidental deletion** | You delete a photo → it's instantly deleted from both RAID drives. Gone. | Backup still has the file from last night's rsync. Recoverable. |
| **Ransomware / malware** | Malware encrypts files → encrypted on both RAID drives simultaneously. Data destroyed. | Backup drive (physically separate, not network-mounted by default) may survive. Recoverable. |
| **File corruption** | A corrupted file is written → corruption is mirrored to both drives instantly. RAID thinks it's fine. | Backup has the uncorrupted version from the last successful rsync. Recoverable. |
| **NAS failure** (power supply, controller board) | Both drives are physically inside the failed NAS. Even if the drives are fine, you can't access them until the NAS is repaired or replaced. | Backup drive is plugged into the K10 (separate device). Photos accessible immediately. |
| **Physical disaster** (fire, flood, theft) | NAS and both drives are destroyed together. Total loss. | If the backup drive survives (different location in the room), data is recoverable. For true protection, an off-site backup is needed (see Future Improvements). |
| **Software bug** | An Immich update corrupts the photo database → corruption propagated to both RAID drives via normal operation. | Backup contains the pre-update config. Roll back by restoring from the backup drive. |
 
### Summary
 
> **RAID keeps you running when a drive dies. Backups keep your data safe when everything else goes wrong.**
 
Both are needed. RAID without backup is a single point of failure with a false sense of security. This setup uses both — RAID 1 for instant hardware fault tolerance, plus nightly rsync for everything RAID can't protect against.
 
---
 
## Three-Layer Protection Strategy
 
```
┌─────────────────────────────────────────────────────────────┐
│                     LAYER 1: RAID 1                         │
│              NAS Pool 2 — 2× 4TB Mirrored                   │
│                                                             │
│  ┌─────────┐    identical    ┌─────────┐                    │
│  │ Drive A │ ◄────────────►  │ Drive B │                    │
│  │  4TB    │    real-time    │  4TB    │                    │
│  └─────────┘                 └─────────┘                    │
│                                                             │
│  Protects against: single drive failure                     │
│  Does NOT protect: deletion, corruption, NAS failure        │
│  Speed: instant (continuous mirroring)                      │
│  Recovery: automatic rebuild when dead drive is replaced    │
└─────────────────────────────────────────────────────────────┘
                            │
                    NFS mount over ethernet
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                     LAYER 2: RSYNC                          │
│             WD Elements 5TB — USB 3.0 to K10                │
│                                                             │
│  ┌──────────────────┐    nightly  ┌──────────────────┐      │
│  │ /mnt/nas/photos  │ ──────────► │/mnt/backup/photos│      │ 
│  │ (NAS, 4TB)       │   3:00 AM   │ (ext HDD, 5TB)   │      │ 
│  └──────────────────┘             └──────────────────┘      │
│  ┌──────────────────┐    nightly   ┌──────────────────┐     │
│  │ ~/docker/        │ ──────────►  │ /mnt/backup/     │     │
│  │ (K10 SSD)        │   3:00 AM    │  docker-config/  │     │
│  └──────────────────┘              └──────────────────┘     │
│                                                             │
│  Protects against: deletion, corruption, NAS failure,       │
│                    bad updates, software bugs               │
│  Does NOT protect: physical disaster (same location)        │
│  Speed: incremental (only changed files, usually < 1 min)   │
│  Recovery: manual rsync back to source                      │
└─────────────────────────────────────────────────────────────┘
                            │
                     separate device
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                     LAYER 3: MONITORING                     │
│                      Uptime Kuma                            │
│                                                             │
│  HTTP checks every 60 seconds:                              │
│    ✓ Immich server responding                               │
│    ✓ NAS NFS mounts accessible                              │
│    ✓ All Docker containers running                          │
│    ✓ External HDD mounted at /mnt/backup                    │
│                                                             │
│  Alerts via push notification if any check fails.           │
│  You'll know within 60 seconds if something goes down —     │
│  not days later when you try to access a photo.             │
└─────────────────────────────────────────────────────────────┘
```
 
### Why three layers?
 
Each layer catches what the others miss:
 
- **RAID 1** handles the most common failure (a drive dying) with zero intervention — the NAS keeps running without you even noticing.
- **rsync to external HDD** handles everything RAID can't — deletion, corruption, NAS-wide failures — with a one-day recovery point (you lose at most the last 24 hours of changes).
- **Uptime Kuma** ensures you find out about problems immediately instead of discovering data loss weeks later. A backup that failed silently two months ago is as useless as no backup at all.
 
---
 
## Disaster Recovery Procedures
 
### Scenario 1: Single NAS Drive Fails (RAID 1 auto-recovery)
 
**Symptoms:** UGOS Pro sends a notification that a drive has failed. The NAS continues operating normally on the surviving drive.
 
**Impact:** None. All data remains accessible. Performance may be slightly reduced during rebuild.
 
**Recovery steps:**
 
1. **Don't panic** — RAID 1 is designed for this. Your data is safe on the surviving drive
2. Open UGOS Pro web UI → **Storage Manager** → confirm pool status shows "Degraded"
3. Order the same model replacement drive (same capacity or larger)
4. **Power off** the NAS → physically remove the failed drive → insert the replacement
5. Power on → UGOS Pro will detect the new drive and prompt you to rebuild the array
6. Start the rebuild — this runs in the background and typically takes several hours for a 4TB drive
7. Once complete, pool status returns to "Healthy"
8. **Verify:** check that Immich photos are accessible and the nightly rsync runs successfully
 
**Time to recover:** Drive replacement + rebuild time. Data is accessible the entire time.
 
---
 
### Scenario 2: K10 Dies Completely (full server rebuild)
 
**Symptoms:** The GMKtec K10 won't boot, or the internal SSD has failed. All Docker containers are offline. The NAS and external backup drive are unaffected.
 
**Impact:** All services are down. Data on the NAS and backup drive is safe.
 
**Recovery steps:**
 
1. **Assess the failure** — if it's a power supply or SSD issue, the K10 hardware may be repairable. If the K10 is dead, buy a replacement mini PC.
 
2. **Install a fresh Ubuntu Server 24.04** on the K10 (or replacement):
   ```bash
   # Follow the same process as the original setup:
   # Flash Ubuntu ISO → install → set username + password → enable SSH
   ```
 
3. **Set the static IP** to `192.168.1.101` (same as before) so NFS mounts and bookmarks still work:
   ```bash
   sudo nano /etc/netplan/00-installer-config.yaml
   # Set addresses: 192.168.1.101/24
   sudo netplan apply
   ```
 
4. **Install Docker:**
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo usermod -aG docker $USER
   ```
 
5. **Mount the external backup drive:**
   ```bash
   sudo mkdir -p /mnt/backup
   sudo mount /dev/sdX1 /mnt/backup  # Replace sdX1 with actual device
   ```
 
6. **Restore Docker configs from the backup drive:**
   ```bash
   # Copy all app configs back to the home directory
   rsync -av /mnt/backup/docker-config/ ~/docker/
   ```
 
7. **Recreate NAS mount points and mount:**
   ```bash
   sudo mkdir -p /mnt/nas/photos /mnt/nas/data
   sudo apt install -y nfs-common
 
   # Add to /etc/fstab:
   # 192.168.1.100:/photos  /mnt/nas/photos  nfs  defaults,_netdev  0  0
   # 192.168.1.100:/data    /mnt/nas/data    nfs  defaults,_netdev  0  0
   sudo mount -a
   ```
 
8. **Start the stack:**
   ```bash
   cd ~/docker
   docker compose up -d
   ```
 
9. **Verify everything:**
   ```bash
   docker compose ps               # All containers should show "Up"
   curl http://localhost:8989      # Sonarr responding
   curl http://localhost:32400/web # Plex responding
   curl http://localhost:2283      # Immich responding
   ```
 
**Time to recover:** 30–60 minutes for a clean rebuild. All data intact, all app settings restored.
 
---
 
### Scenario 3: NAS Photos Pool Fails (both drives or NAS hardware)
 
**Symptoms:** The NAS's RAID 1 photos pool is inaccessible — either both drives failed simultaneously (extremely rare), the NAS controller died, or physical damage occurred.
 
**Impact:** Immich can't read or write photos. The web UI may show errors. But the external backup drive has a complete copy from the last nightly rsync.
 
**Recovery steps:**
 
1. **Confirm the backup drive has the latest photos:**
   ```bash
   # Check the backup directory exists and has recent files
   ls -lah /mnt/backup/photos/ | head -20
 
   # Check the backup log for the last successful run
   tail -20 ~/backup.log
   ```
 
2. **If the NAS hardware is dead — replace it:**
   - Purchase a replacement NAS (or any device that can host NFS shares)
   - Install new drives, create a new RAID 1 pool, create the `photos` shared folder
   - Enable NFS with read/write permissions
 
3. **Restore photos from the backup drive to the new NAS:**
   ```bash
   # Mount the new NAS share
   sudo mount -a  # (assuming fstab already has the entry)
 
   # Rsync the backup back to the NAS
   rsync -av /mnt/backup/photos/ /mnt/nas/photos/
   ```
 
4. **Restart Immich:**
   ```bash
   cd ~/docker
   docker compose restart immich_server immich_ml immich_postgres immich_redis
   ```
 
5. **Verify in Immich web UI** — browse the timeline, confirm photo count matches, spot-check recent uploads
 
**Time to recover:** Depends on NAS replacement time. The rsync restore of ~400GB+ of photos takes approximately 1–2 hours over gigabit ethernet. All photos intact from the last backup.
 
**Data loss:** At most 24 hours of photos (anything uploaded between the last 3am backup and the failure). The Immich iPhone app retains originals locally until confirmed uploaded — recent photos may still be recoverable from the phone.
 
---
 
## WD Elements Drive Lifecycle
 
The WD Elements 5TB external HDD serves two distinct purposes in sequence — it's never idle.
 
### Phase 1: iCloud Transfer Medium 
 
```
┌──────────┐     iCloud for     ┌──────────────┐     Immich web    ┌─────────────┐
│  iCloud  │ ──── Windows ────► │ WD Elements  │ ──── upload ────► │   Immich    │
│  (cloud) │     overnight      │ 5TB (NTFS)   │     bulk folder   │ /mnt/nas/   │
│  ~400GB  │                    │ plugged into │                   │   photos    │
└──────────┘                    │ Windows PC   │                   └─────────────┘
                                └──────────────┘
```
 
**Why the WD Elements is needed:** The iPhone has a 256GB capacity but the iCloud library is ~400GB — the phone stores only thumbnails locally, with originals in the cloud. You can't upload directly from the phone because it doesn't have room to download the full-resolution files. The WD Elements acts as a large-capacity staging area: download the entire iCloud library onto it via a Windows PC, then bulk upload to Immich.
 
### Phase 2: Permanent Nightly Backup Drive
 
```
┌──────────────┐                 ┌──────────────┐
│ WD Elements  │                 │ WD Elements  │
│ 5TB (NTFS)   │ ── reformat ──► │ 5TB (ext4)   │
│ iCloud data  │     as ext4     │ plugged into │
│ (no longer   │                 │ K10 via USB  │
│  needed)     │                 │ /mnt/backup  │
└──────────────┘                 └──────────────┘
```
 
Once the iCloud migration is complete and verified:
 
1. The iCloud data on the WD Elements is no longer needed (it's all in Immich now)
2. The drive is **reformatted as ext4** (Linux native filesystem — faster and more reliable than NTFS for this use case)
3. It's **plugged into the K10** via USB 3.0
4. Mounted at `/mnt/backup` with the `nofail` flag in fstab (so the K10 still boots if the drive is unplugged)
5. The nightly rsync cron job writes to this drive at 3am every night
 
**Why ext4 over NTFS?** The backup drive is only read by Linux (the K10). ext4 is Linux's native filesystem with full permission support, journaling, and no overhead from NTFS compatibility layers. It's faster, more reliable, and supports Linux file ownership natively — important because the backup preserves file permissions from the source.
 
---
 
## Future Improvements
 
The current backup strategy covers the most critical scenarios — drive failure, accidental deletion, server death, and NAS failure. However, there are several areas that could be strengthened:
 
### Off-site backup (3-2-1 strategy)
 
The industry standard for data protection is the **3-2-1 rule**: three copies of your data, on two different types of media, with one copy off-site. Currently this setup has:
 
- ✅ **3 copies** — NAS drive A, NAS drive B (RAID 1), external HDD
- ✅ **2 media types** — NAS internal drives + USB external drive
- ❌ **1 off-site** — not yet implemented
 
Options for off-site backup:
- **Backblaze B2** — cloud object storage (~£3.50/TB/month). Upload encrypted photos via `rclone` on a schedule.
- **Second external HDD** stored at a friend's or family member's house, swapped periodically.
- **Tailscale + rsync to a remote machine** — if you have a second server or a friend with a home lab.
 
### Backup verification checksums
 
Currently, rsync checks file sizes and timestamps but doesn't verify file integrity with checksums. Adding `--checksum` to the rsync flags would detect silent corruption but significantly slows down each backup run. A better approach would be a weekly verification script that checksums a random sample of backed-up files.
 
### Email or push notification on failure
 
The current cron job logs output to a file but doesn't alert on failure. If the backup drive fails or fills up, the only way to know is by manually checking the log. Adding a health check to Uptime Kuma that monitors the backup log's last-modified timestamp would catch silent failures — if the log hasn't been updated in 36 hours, something is wrong.
 
### Immich database export
 
The current strategy excludes `immich/pgdata` from rsync (risky to copy mid-write). A better approach would be adding a `pg_dump` command to the backup script that exports the Immich PostgreSQL database to a SQL file before rsync runs. This would back up face recognition data, album structures, and sharing settings in a consistent, restorable format.
 
---
 
*[← Photo Backup](photo-backup.md) · [Back to README](../README.md)*
