#!/bin/bash
LOG=/mnt/backup/backup.log
echo "=== Backup started: $(date) ===" >> $LOG

# Mirror Immich photos from RAID 1 pool to external HDD
# --delete keeps the backup in sync: if you delete from Immich, it deletes here too
# This means the backup drive never fills up with old photos
rsync -av --delete /mnt/nas/photos/ /mnt/backup/photos/ >> $LOG 2>&1

# Back up Docker configs (settings, databases — not media)
rsync -av --delete ~/docker/ /mnt/backup/docker-config/ \
  --exclude='plex/config/Library' \
  --exclude='immich/pgdata' >> $LOG 2>&1

echo "=== Backup complete: $(date) ===" >> $LOG
