# 🐳 Docker Setup

> Installing Docker, structuring the Compose file, and managing the container stack.

---

## Why Docker?

All services run as Docker containers rather than being installed directly on the OS:

- **Isolation** — each app has its own environment with no dependency conflicts
- **Portability** — the entire stack rebuilds on any machine from the Compose file
- **Easy updates** — Watchtower automatically pulls new images at 4am daily
- **Clean removal** — stopping a container and deleting its config folder removes it completely

---

## Installation

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
```

---

## Folder Structure

```
~/docker/
├── docker-compose.yml
├── .env                        ← credentials (never committed)
├── .gitignore                  ← excludes .env
├── immich.env                  ← Immich database credentials
├── plex/config/
├── sonarr/config/
├── sonarr-anime/config/
├── radarr/config/
├── bazarr/config/
├── seerr/config/
├── recyclarr/recyclarr.yml     ← TRaSH quality profile sync config
├── portainer/data/
├── adguard/{work,conf}/
├── uptime-kuma/data/
├── homarr/{configs,icons}/
└── immich/{pgdata,model-cache}/
```

Config folders live on the K10's local SSD (fast I/O). Media and photos live on the NAS (large capacity via NFS). All config folders are backed up nightly to the external HDD via rsync — see [Backup & Disaster Recovery](backup-disaster-recovery.md).

---

## Networking

All containers (except Plex) share a custom Docker bridge network called `medianet`:

```yaml
networks:
  medianet:
    driver: bridge
```

Containers reach each other using **container names as hostnames** — Sonarr connects to other services at `http://containername:port` without needing IP addresses.

**Plex uses `network_mode: host`** for local network discovery and direct streaming performance.

---

## Credential Management

Secrets are stored in `~/docker/.env` (excluded from Git via `.gitignore`) and referenced in the Compose file as `${VARIABLE}` placeholders:

```bash
chmod 600 ~/docker/.env    # only owner can read
```

The `.env` file contains VPN credentials, Cloudflare tunnel tokens, and other secrets. It is backed up nightly by rsync but **never** committed to GitHub — the `.gitignore` ensures this. Template files (`.env.example`, `immich.env.example`) are committed to show the required variable names without real values.

---

## Docker Log Rotation

Without this, Docker logs grow indefinitely. A global config caps each container at 30MB max:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

Saved to `/etc/docker/daemon.json`, applied with `sudo systemctl restart docker`.

---

## Key Commands

```bash
cd ~/docker && docker compose up -d         # Start all
docker compose ps                           # Status check
docker compose logs sonarr                  # View logs
docker compose logs -f sonarr               # Follow live
docker compose restart sonarr               # Restart one
docker compose down                         # Stop all
docker compose pull && docker compose up -d # Update all
docker system df                            # Disk usage
```

> 📷 *[Docker Container Status](../assets/screenshots/docker-compose-ps.png) — all containers running]*
> 
> 📷 *[Portainer Dashboard](../assets/screenshots/portainer-dashboard.png) — Portainer container list]*

---

## Full Compose File

See [`config/docker-compose.yml`](../config/docker-compose.yml) for the production configuration defining all 23 containers on the `medianet` bridge network.

---

*[← OS Setup](os-setup.md) · [Back to README](../README.md) · [Media Stack →](media-stack.md)*
