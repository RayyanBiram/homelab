# 🎬 Media Stack

> Plex, Sonarr, Radarr, Bazarr and Seerr - media library management, streaming, and a self-service request portal.

---

## Architecture

```
┌──────────────┐
│    Seerr     │  seerr.biram.uk (Cloudflare Tunnel)
│  Request UI  │  Household members sign in with their Plex accounts
└──────┬───────┘
       │ API
       ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│    Sonarr    │    │    Radarr    │    │ Sonarr Anime │
│  TV :8989    │    │ Films :7878  │    │   :8990      │
│  Organise,   │    │  Organise,   │    │ Anime naming │
│  rename,     │    │  rename,     │    │ and absolute │
│  metadata    │    │  metadata    │    │ numbering    │
└──────┬───────┘    └──────┬───────┘    └──────┬───────┘
       │                   │                   │
       ▼                   ▼                   ▼
          ┌────────────────────────┐    ┌──────────┐
          │  /data/media/          │    │  Bazarr  │
          │  ├─ tv/                │◄───│Subtitles │
          │  ├─ movies/            │    │  :6767   │
          │  └─ anime/             │    └──────────┘
          └───────────┬────────────┘
                      ▼
          ┌────────────────────────┐
          │         Plex           │
          │      :32400/web        │
          │  Intel Quick Sync HW   │
          │     transcoding        │
          └────────────────────────┘
```

All media lives on the NAS's `data` share (RAID 0), mounted on the K10 over NFS at `/mnt/nas/data` and passed into each container as `/data`.

---

## Applications

### Plex - Media Server (:32400)

Indexes and streams the media library to smart TVs, phones, browsers, Apple TV and Fire TV. Intel Quick Sync on the i9-13900HK's integrated GPU handles hardware transcoding, so video conversion does not load the CPU. Hardware transcoding requires Plex Pass.

Plex runs with `network_mode: host` so devices on the LAN can discover it, and the GPU is passed in with `/dev/dri`.

Libraries: **TV Shows** (`/data/media/tv`), **Movies** (`/data/media/movies`), **Anime** (`/data/media/anime`)

> 📷 *[Plex](../assets/screenshots/plex-libraries.png)*

---

### Sonarr - TV Library Management (:8989)

Manages the TV library: organises files, renames them to a consistent format, and fetches metadata and artwork. Connected to Plex so the library refreshes automatically.

Root folder: `/data/media/tv`

---

### Sonarr Anime - Anime Library Management (:8990)

A separate Sonarr instance with anime-specific settings: absolute episode numbering and its own naming rules. Running anime separately avoids naming conflicts with Western TV.

Root folder: `/data/media/anime`

---

### Radarr - Film Library Management (:7878)

Same concept as Sonarr, for films. Organises and renames files and keeps metadata and artwork up to date.

Root folder: `/data/media/movies`

---

### Bazarr - Subtitle Automation (:6767)

Reads the Sonarr and Radarr libraries over their APIs, finds matching subtitles from providers such as OpenSubtitles, and writes the subtitle files next to each title, where Plex picks them up automatically. Bazarr never keeps its own list of what exists: the library managers are the source of truth.

---

### Seerr - Request Portal (:5055)

A web portal where household members browse and request titles. Requests are passed to Sonarr or Radarr over their APIs, and trusted users are auto-approved. Available publicly at `https://seerr.biram.uk` through Cloudflare Tunnel, with sign-in delegated to existing Plex accounts.

> 📷 *[Seerr Portal](../assets/screenshots/seerr-portal.png)*

---

### Cloudflare Tunnel (cloudflared)

An outbound-only tunnel to Cloudflare's network. Publishes `seerr.biram.uk` and `immich.biram.uk` with automatic HTTPS. No router ports are opened for these services and the home IP is never revealed. Immich is additionally protected by a Cloudflare Access policy (email allowlist). Any hostname without a route falls through to a catch-all 404.

> 📷 *[Cloudflare Tunnel](../assets/screenshots/cloudflare-tunnel.png)*

---

### Plex Remote Access

Plex remote streaming is the one service that uses a router port forward rather than the tunnel. The ISP originally had the connection behind CGNAT, so the forward could not work until the ISP assigned a static public IP. Everything else is either private (Tailscale) or published through the tunnel.

---

## Inter-App Communication

Apps on the `medianet` bridge reach each other by container name:

| Connection | Hostname URL |
|---|---|
| Seerr → Sonarr | `http://sonarr:8989` |
| Seerr → Radarr | `http://radarr:7878` |
| Bazarr → Sonarr | `http://sonarr:8989` |
| Bazarr → Radarr | `http://radarr:7878` |
| Cloudflared → Seerr | `http://seerr:5055` |
| Cloudflared → Immich | `http://immich-server:2283` |

Plex is the exception: it uses host networking, so other containers reach it through the host's IP rather than by container name.

---

## Media Folder Structure

```
/data/
└── media/
    ├── tv/         ← Sonarr root folder
    ├── movies/     ← Radarr root folder
    ├── anime/      ← Sonarr Anime root folder
    └── music/
```

Every media container mounts the same `/mnt/nas/data` path as `/data`, so file paths are identical in every app.

---

*[← Docker Setup](docker-setup.md) · [Back to README](../README.md) · [Photo Backup →](photo-backup.md)*
