# 🎬 Media Stack

> Plex, Sonarr, Radarr, Bazarr, Seerr, Prowlarr, Recyclarr — media library management and streaming.

---

## Architecture

The media stack uses specialised tools to manage and serve a personal media library:

```
┌──────────────┐
│    Seerr     │  seerr.biram.uk (Cloudflare Tunnel)
│  Request UI  │  Household members & friends browse and request content
└──────┬───────┘
       │ API
       ▼
┌──────────────┐    ┌──────────────┐   ┌──────────────┐
│    Sonarr    │    │    Radarr    |   │ Sonarr Anime │
│  TV :8989    │    │ Movies :7878 │   │   :8990      │
│  Organise,   │    │  Organise,   │   │Anime-specific│
│  rename,     │    │  rename,     │   │ profiles     │
│  metadata    │    │  metadata    │   │              │
└──────┬───────┘    └──────┬──────┘    └──────┬───────┘
       │                   │                  │
       ▼                   ▼                  ▼
┌──────────────────────────────────────────────────────┐
│           Prowlarr — Indexer Manager :9696           │
│  NZBGeek · NZBFinder · IPTorrents · 1337x            │
│  Syncs indexers to all *arr apps automatically       │
└──────────────────────────────────────────────────────┘
       │                   │
       ▼                   ▼
┌──────────────┐    ┌──────────────┐
│   SABnzbd    │    │ qBittorrent  │
│ Usenet :8080 │    │ Torrent :8090│
│              │    │ via Gluetun  │
│              │    │  VPN tunnel  │
└──────────────┘    └──────────────┘
       │                   │
       └───────────┬───────┘
                   ▼
          ┌────────────────┐    ┌──────────┐
          │  /data/media/  │    │  Bazarr  │
          │  ├─ tv/        │───▶│Subtitles │
          │  ├─ movies/    │    │  :6767   │
          │  └─ anime/     │    └──────────┘
          └───────┬────────┘
                  ▼
          ┌────────────────┐    ┌──────────────┐
          │     Plex       │    │  Recyclarr   │
          │  :32400/web    │    │ TRaSH quality│
          │  Intel QS HW   │    │ profile sync │
          │  transcoding   │    │ to Sonarr +  │
          └────────────────┘    │ Radarr       │
                                └──────────────┘
```

---

## Applications

### Plex — Media Server (:32400)

Indexes and streams the media library to any device — smart TVs, phones, browsers, Apple TV, Amazon firestick. Intel Quick Sync on the i9-13900HK handles hardware transcoding (10+ simultaneous streams at near-zero CPU). Requires Plex Pass for HW transcoding.

Libraries configured: **TV Shows** (`/data/media/tv`), **Movies** (`/data/media/movies`), **Anime** (`/data/media/anime`)

> 📷 *[Plex Libraries](../assets/screenshots/plex-libraries.png)*

---

### Sonarr — TV Library Management (:8989)

Manages the TV show library — organises files, renames them to a consistent format, fetches metadata and artwork, and monitors for new content. Connected to Plex for automatic library updates.

Root folder: `/data/media/tv`

---

### Sonarr Anime — Anime Library Management (:8990)

Separate Sonarr instance with anime-specific settings: absolute episode numbering, 10-bit video preference, dual-audio support, and dedicated quality profiles. Running anime separately avoids naming and quality conflicts with Western TV shows.

Root folder: `/data/media/anime`

---

### Radarr — Movie Library Management (:7878)

Same concept as Sonarr, but for movies. Manages the movie library, organises and renames files, and monitors for quality upgrades of existing titles.

Root folder: `/data/media/movies`

---

### Prowlarr — Indexer Manager (:9696)

Centralised indexer management. Four indexers are configured once in Prowlarr and automatically synced to all three *arr instances (Sonarr, Radarr, Sonarr Anime):

| Indexer | Type | Access |
|---|---|---|
| NZBGeek | Usenet | ~£10/yr subscription |
| NZBFinder | Usenet | ~£8/yr subscription |
| IPTorrents | Torrent (private) | One-off ~£7.50 fee |
| 1337x | Torrent (public) | Free |

Without Prowlarr, each indexer would need to be added individually to each *arr app (12 configurations). Prowlarr reduces this to 4 + 3 app connections.

---

### SABnzbd — Usenet Downloader (:8080)

Downloads files from Usenet via the Eweka provider (EU servers, SSL on port 563). Sonarr and Radarr send download requests to SABnzbd via its API. Categories (`tv`, `movies`, `anime`) ensure downloaded files end up in the correct folders.

---

### qBittorrent — Torrent Client (:8090, via Gluetun VPN)

Handles torrent downloads. All traffic routes through the **Gluetun VPN container** (connected to ProtonVPN Plus with port forwarding), ensuring the home IP is never exposed to torrent peers. Categories match Sonarr/Radarr expectations for automatic import.

---

### Recyclarr — TRaSH Quality Profile Sync

Automatically syncs community-maintained quality profiles, custom formats, and scoring from TRaSH Guides into Sonarr and Radarr. Runs on a schedule — ensures optimal quality settings without manual upkeep. Configuration at `~/docker/recyclarr/recyclarr.yml` (API keys redacted in the repo copy at `config/recyclarr.yml`).

---

### Bazarr — Subtitle Automation (:6767)

Watches the Sonarr and Radarr libraries and automatically finds and downloads matching subtitles from providers like OpenSubtitles. Writes subtitle files directly into media folders where Plex picks them up.

---

### Seerr — Request Portal (:5055)

A polished web UI where household members can browse, search, and request movies or TV shows. Requests are forwarded to Radarr or Sonarr via API. Accessible publicly at `https://seerr.biram.uk` via Cloudflare Tunnel — users log in with their Plex account.

> 📷 *[Seerr Portal](../assets/screenshots/seerr-portal.png)*

---

### Cloudflare Tunnel (cloudflared)

Outbound-only tunnel to Cloudflare's edge network. Exposes `seerr.biram.uk` and `immich.biram.uk` publicly with automatic HTTPS. No router port forwarding needed, home IP never revealed. Immich is additionally protected by a Cloudflare Access policy (email allowlist).

> 📷 *[Cloudflare Tunnel](../assets/screenshots/cloudflare-tunnel.png)*

---

## Inter-App Communication

All apps communicate using Docker container names as hostnames on the `medianet` bridge:

| Connection | Hostname URL |
|---|---|
| Seerr → Sonarr | `http://sonarr:8989` |
| Seerr → Radarr | `http://radarr:7878` |
| Prowlarr → Sonarr | `http://sonarr:8989` |
| Prowlarr → Radarr | `http://radarr:7878` |
| Prowlarr → Sonarr Anime | `http://sonarr-anime:8989` |
| Bazarr → Sonarr | `http://sonarr:8989` |
| Bazarr → Radarr | `http://radarr:7878` |
| Sonarr → SABnzbd | `http://sabnzbd:8080` |
| Sonarr → qBittorrent | `http://gluetun:8090` |
| Cloudflared → Seerr | `http://seerr:5055` |
| Cloudflared → Immich | `http://immich-server:2283` |

---

## Media Folder Structure

All media lives on the NAS's `/data` share (RAID 0, 24TB), mounted via NFS at `/mnt/nas/data`:

```
/data/
├── media/
│   ├── tv/         ← Sonarr root folder
│   ├── movies/     ← Radarr root folder
│   ├── anime/      ← Sonarr Anime root folder
│   └── music/
├── usenet/
│   ├── tv/         ← SABnzbd download category
│   ├── movies/
│   └── anime/
└── torrents/
    ├── tv/         ← qBittorrent download category
    ├── movies/
    └── anime/
```

Downloads and media share the same `/data` root to enable **hardlinks** — when Sonarr/Radarr "import" a completed download, the file is instantly linked (no copying) because source and destination are on the same filesystem.

---

*[← Docker Setup](docker-setup.md) · [Back to README](../README.md) · [Photo Backup →](photo-backup.md)*
