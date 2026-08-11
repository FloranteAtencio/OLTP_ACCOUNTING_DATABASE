#!/bin/bash

set -e

BACKUP_DIR="/backup"
LOG_DIR="/log"
LOG_FILE="$LOG_DIR/backup.log"

CONTAINER_NAME="erp_postgres"
DB_USER="erp_admin"

EXTERNAL_DRIVE="/mnt/external-backup"

RETENTION_DAYS=30

mkdir -p "$BACKUP_DIR"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +%F_%H-%M-%S)

TEMP_BACKUP="/tmp/base_${TIMESTAMP}"
BACKUP_NAME="base_backup_${TIMESTAMP}.tar.gz"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

echo "[$(date)] Backup started" >> "$LOG_FILE"

# 1. Create physical base backup inside PostgreSQL container

docker exec "$CONTAINER_NAME" pg_basebackup \
    -D "$TEMP_BACKUP" \
    -Ft \
    -z \
    -P \
    -U "$DB_USER" \
    -Xs

# 2. Copy backup outside container

docker cp \
    "$CONTAINER_NAME:$TEMP_BACKUP" \
    "$BACKUP_DIR/base_${TIMESTAMP}"

# 3. Remove temporary container backup

docker exec "$CONTAINER_NAME" \
    rm -rf "$TEMP_BACKUP"

# 4. Package backup

cd "$BACKUP_DIR"

tar -czf \
    "$BACKUP_NAME" \
    "base_${TIMESTAMP}"

rm -rf "base_${TIMESTAMP}"

# 5. Copy to external storage only if actually mounted

if mountpoint -q "$EXTERNAL_DRIVE"; then

    cp "$BACKUP_PATH" "$EXTERNAL_DRIVE/"

    echo "[$(date)] Backup copied to external storage" >> "$LOG_FILE"

else

    echo "[$(date)] WARNING: External storage not mounted" >> "$LOG_FILE"

fi

# 6. Local retention

find "$BACKUP_DIR" \
    -name "base_backup_*.tar.gz" \
    -mtime +"$RETENTION_DAYS" \
    -delete

echo "[$(date)] Backup completed: $BACKUP_NAME" >> "$LOG_FILE"