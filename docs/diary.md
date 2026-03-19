# 📓 Build Diary

> A running log of every step taken, every problem encountered, and how it was resolved.

---

## How to Read This

Each entry shows:
- ✅ What was completed
- 🔧 Problems hit and how they were fixed
- 💡 Decisions made and why
- 📸 Screenshots taken for this portfolio

---

## 🗓️ Entries

---

### [14/02/26] — Project Start & Planning

**What I'm building:** A self-hosted home lab consisting of:
- A **GMKtec K10** (i9-13900HK, 16GB RAM) running Ubuntu Server as a Docker host
- A **UGREEN DXP4800 Plus NAS** with 4 drives across 2 RAID pools (RAID 1 for photos, RAID 0 for media)
- A **WD Elements 5TB** external HDD for nightly automated backups
- Everything managed remotely via SSH, browser, Tailscale VPN, and Cloudflare Tunnel

**Why:** Learn Linux server administration hands-on, gain practical Docker and networking experience, build a documented portfolio for IT Support/Sysadmin/DevOps roles, and replace cloud subscriptions with self-hosted alternatives.

---

### [23/02/26] — Ubuntu Server, Static IP, SSH

**Goal:** Get Ubuntu Server 24.04 LTS running on the K10 with a fixed IP and remote SSH access.

1. Flashed Ubuntu Server 24.04 ISO to USB with Balena Etcher
2. Installed on the K10 — selected OpenSSH during install
3. Configured static IP (192.168.1.101) via Netplan
4. Confirmed SSH works from main PC — unplugged monitor permanently

**Decision — why Server over Desktop?** Server uses ~200MB RAM idle vs Desktop's ~1.5GB. With multiple containers running, every MB counts.

> 📸 **[First K10 SSH Connection Established](../assets/screenshots/ssh-connected.png)**

---

### [25/02/26] — XFCE Desktop, xRDP, Tailscale

**Goal:** Set up remote desktop and secure VPN for accessing services from anywhere.

1. Installed XFCE (~300MB RAM) + xRDP for Remote Desktop Protocol access
2. Installed Tailscale with subnet routing — all home devices now accessible remotely
3. Approved subnet routes in Tailscale admin dashboard
4. Configured UFW firewall — only SSH (22) and xRDP (3389) open

**Decision — why Tailscale over port forwarding?** Zero router config, end-to-end encrypted, works through NAT and firewalls. Admin interfaces stay private — only Seerr and Immich are exposed publicly via Cloudflare Tunnel.

> 📸 **[XFCE + xRDP Remote Connection](../assets/screenshots/xfce-remote-desktop.png)**
> 
> 📸 **[Tailscale Dashboard](../assets/screenshots/tailscale-dashboard.png)**
---

### [28/02/26] — NAS First Boot, RAID 1 Photos Pool, NFS Mount

**Goal:** Initialise the DXP4800 Plus NAS with a RAID 1 pool for Immich photos.

1. Connected DXP4800 Plus to router, ran UGOS Pro setup wizard
2. Created Pool 2: 2× 4TB RAID 1 — 4TB usable, one-drive-failure tolerant
3. Created `photos` shared folder, enabled NFS, set read/write permissions
4. Reserved NAS IP (192.168.1.100) via DHCP reservation in router
5. Installed `nfs-common` on K10, mounted `/mnt/nas/photos` via fstab

**Why only the photos pool today?** The 12TB media drives arrive separately. The photos pool is set up first because Immich needs it immediately.

> 📸 **[NAS Raid Pool 1 (Healthy)](../assets/screenshots/ugos-raid1-pool.png)**
> 
> 📸 **[NAS Mounted On To K10](../assets/screenshots/nfs-mount-photos.png)**
---

### [07/03/26] — Docker Install & Container Stack Launch

**Goal:** Deploy the entire container stack from a single Compose file.

1. Installed Docker via official script, added user to `docker` group
2. Created config folder structure for all apps
3. Created `immich.env` with database credentials
4. Created `.env` with service credentials (permissions locked with `chmod 600`)
5. Wrote the full `docker-compose.yml` on the `medianet` bridge network
6. `docker compose up -d` — all 23 containers pulled and started

**Key design decision:** All containers share a single Docker bridge network (`medianet`) and communicate using container names as hostnames. This means Sonarr reaches Bazarr at `http://bazarr:6767` without hardcoded IPs.

> 📸 **[Docker Container Status](../assets/screenshots/docker-compose-ps.png)**

---

### [14/03/26] — App Configuration

**Goal:** Configure and link all services together.

Configured in dependency order so every API key and connection is available when the next app needs it:

1. **Portainer** — Docker GUI for container monitoring and log viewing
2. **SABnzbd** — Usenet downloader, Eweka server configured, API key generated for Sonarr/Radarr
3. **Gluetun** — VPN container verified connected to ProtonVPN with port forwarding active
4. **qBittorrent** — Torrent client routing through Gluetun VPN, TRaSH categories created
5. **Sonarr** — TV library root folder, download clients linked (SABnzbd + qBittorrent), API key generated
6. **Radarr** — Movie library root folder, download clients linked, API key generated
7. **Sonarr Anime** — Separate instance with anime-specific quality profiles and absolute episode numbering
8. **Recyclarr** — TRaSH quality profiles synced to Sonarr and Radarr automatically
9. **Prowlarr** — 4 indexers (NZBGeek, NZBFinder, IPTorrents, 1337x) linked to all three *arr instances
10. **Bazarr** — Linked to Sonarr + Radarr via API, configured OpenSubtitles provider
11. **Plex** — 3 libraries (TV, Movies, Anime), Intel Quick Sync hardware transcoding enabled, friend sharing configured
12. **Cloudflare Tunnel** — Added `seerr.biram.uk` hostname route in Cloudflare dashboard
13. **Seerr** — Linked to Radarr + Sonarr via API, auto-approval enabled, Plex users imported

> 📸 **[Portainer Dashboard](../assets/screenshots/portainer-dashboard.png)**
>
> 📸 **[Sonarr + Radarr Download Clients Connected](../assets/screenshots/sonarr-radarr-download-clients.png)**
> 
> 📸 **[Plex Libraries](../assets/screenshots/plex-libraries.png)**
> 
> 📸 **[Cloudflare Tunnel](../assets/screenshots/cloudflare-tunnel.png)**
> 
> 📸 **[Seerr Portal](../assets/screenshots/seerr-portal.png)**
---

### [16/03/26] — Immich Setup, iCloud Migration, iPhone Backup

**Goal:** Set up self-hosted photo backup and migrate from iCloud.

1. Created Immich admin account at `:2283`
2. Added `immich.biram.uk` to Cloudflare Tunnel
3. Added Cloudflare Access policy (email allowlist) to protect Immich externally
4. Plugged **WD Elements 5TB** into Windows PC, downloaded full iCloud library (~400GB) onto it via iCloud for Windows
5. Bulk uploaded from WD Elements to Immich via web UI
6. Configured Immich iPhone app for automatic Wi-Fi backup
7. Verified photo count, spot-checked older videos
8. Downgraded iCloud to free 5GB plan — WD Elements repurposed as backup drive in next step

> 📸 **[Immich Timeline (Sneak Peek)](../assets/screenshots/immich-timeline.png)**

---

### [19/03/26] — Final Config: Logs, Monitoring, Backup & Disaster Recovery

1. **Docker log rotation** — 10MB cap per log, 3 rotations (30MB max per container)
2. **Credential security** — Verified `.env` and `immich.env` permissions are `600` (owner-only read)
3. **Plex hardware transcoding** — Intel Quick Sync enabled (requires Plex Pass)
4. **AdGuard Home** — Network-wide ad blocking, DNS rewrites for local hostnames (e.g. `sonarr.home`)
5. **Uptime Kuma** — HTTP monitors for all services, push notifications on failure
6. **External HDD backup** — Reformatted the WD Elements 5TB (previously used for iCloud transfer) as ext4, plugged into K10, mounted at `/mnt/backup` with `nofail` in fstab
7. **Backup script** — Created `backup.sh` using rsync to back up Immich photos + Docker configs nightly at 3am via cron
8. **Backup documentation** — Documented the full three-layer backup strategy, rsync script breakdown, and disaster recovery procedures for three failure scenarios

**Decision — three-layer backup strategy:** RAID 1 handles drive failure (instant, automatic). Nightly rsync to external HDD handles deletion, corruption, and NAS-wide failure. Uptime Kuma catches silent failures within 60 seconds. Full details in [Backup & Disaster Recovery](backup-disaster-recovery.md).

> 📸 **[AdGuard Dashboard](../assets/screenshots/adguard-dashboard.png)**
>
> 📸 **[Uptime Kuma Dashboard](../assets/screenshots/uptime-kuma.png)**
---

## 🔧 Problems & Fixes Log

| # | Problem | Cause | Fix |
|---|---|---|---|
| 1 | Media containers showing path-not-found errors | `/mnt/nas/data` not yet mounted (12TB drives hadn't arrived) | Expected — cleared automatically once the share was mounted and containers restarted |
| 2 | Immich iOS app couldn't connect externally | Cloudflare Access was blocking API requests | App authenticates via API directly — worked after hostname was added to tunnel |
| 3 | AdGuard Home couldn't bind to port 53 | `systemd-resolved` was already using port 53 | Disabled `systemd-resolved`, AdGuard took over DNS |
| 4 | SABnzbd not accessible from outside the container | `inet_exposure` defaulted to local only | Set `inet_exposure=4` in SABnzbd config (container must be stopped first to edit) |
| 5 | qBittorrent categories not saving via browser | WebUI right-click context menu unreliable | Created categories via curl API calls instead |
| 6 | NFS mount failing with wrong path | Used `/photos` instead of `/volume1/photos` | UGREEN NAS exports use `/volume1/[share]` format |
| 7 | Plex remote access non-functional due to port forwarding being blocked | ISP CGNAT configuration was blocking any port forwarding | Contacted ISP to assign static IP which opened up external communication through open ports |
---

## 🔮 Future Improvements

- [ ] Set up off-site backup for true 3-2-1 strategy (Backblaze B2 or remote rsync)
- [ ] Add `pg_dump` to backup script for Immich PostgreSQL database export
- [ ] Add backup failure notifications via Uptime Kuma log monitoring
- [ ] Write Ansible playbook to automate K10 rebuild from scratch
- [ ] Add Grafana + Prometheus for detailed system metrics
- [ ] Explore Traefik reverse proxy as alternative to Cloudflare Tunnel
- [ ] Add Authelia for SSO across internal services
- [ ] Implement backup verification checksums on a weekly schedule

---

*Diary updated as the build progresses — check commit history for timestamps*
