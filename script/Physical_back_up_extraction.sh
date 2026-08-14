#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# --- Configuration ---
BACKUP_DIR="../backup"
LOG_DIR="../log"
RESTORE_DIR="../restore"
LOG_FILE="$LOG_DIR/backup.log"

CONTAINER_NAME="erp_postgres"
DB_USER="erp_admin"
DB_NAME="erp_db"

log_msg() {
    echo "[$(date)] $1" >> "$LOG_FILE"
    echo "[$(date)] $1" # Also print to console for debugging
}

log_msg "Restore started"

if [ -z "$1" ]; then
    echo "Usage: $0 <backup-file>"
    echo "Example: $0 erp_2026-03-20_02-00-00.tar.gz"
    echo ""
    echo "Available backups:"
    ls -lh "$BACKUP_DIR"/base_*.tar.gz 2>/dev/null || echo "No backups found"
    exit 1
fi

BACKUP_FILE="$1"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILE"

# Verify backup exists
if [ ! -f "$BACKUP_PATH" ]; then
    log_msg "✗ Backup file not found: $BACKUP_PATH"
    exit 1
fi

log_msg "Starting two-stage extraction..."

# 1. Create a temporary working directory
WORK_DIR=$(mktemp -d)
log_msg "Working directory: $WORK_DIR"

# 2. Extract the outer .tar.gz to get the inner base.tar
if tar -xzf "$BACKUP_PATH" -C "$WORK_DIR"; then

    log_msg "Step 1: Outer archive extracted."

    INNER_TAR=$(ls "$WORK_DIR"*.tar 2>/dev/null | head -n 1)

    if [ -z "$INNER_TAR" ]; then
        log_msg "Step 2: Found inner archive "

        INNER_TAR=$(ls "$WORK_DIR"/base.tar.gz 2>/dev/null | head -n 1)

        if tar -xf "$INNER_TAR" -C "$RESTORE_DIR"; then
            log_msg "Step 3: Inner archive extracted successfully to $DATA_DIR"
            VOLUME_PATH="/var/lib/docker/volumes/erp_postgres_pgdata/_data"

            sudo mv "$RESTORE_DIR"/* "$VOLUME_PATH"/
                # 8. FIX PERMISSIONS (CRITICAL)
            sudo chown -R 999:999 "$VOLUME_PATH"
                
                # 9. CREATE RECOVERY SIGNAL
            sudo touch "$VOLUME_PATH/recovery.signal"
            sudo chown 999:999 "$VOLUME_PATH/recovery.signal"
                
            log_msg "Restoration complete! Container is ready to start."
                            
            rm -rf "$WORK_DIR"
            rm -rf "$DATA_DIR"
                

    

            #Optional: Start container immediately if desired
            #docker-compose -f ./docker/docker-compose.prod.yml -p erp_postgres up -d
        else
            log_msg "ERROR: No valid PostgreSQL data found inside the inner archive."
            exit 1
        fi
    
    else
    
        log_msg "ERROR: Failed to extract inner base.tar"
        exit 1
    
    fi

else

    log_msg "ERROR: Failed to extract outer archive"
    rm -rf "$WORK_DIR"
    exit 1

fi    

RECOVERY_TIME="${2:-$(date -d '1 hour ago' '+%Y-%m-%d %H:%M:%S')}" # Default to 1 

CONFIG_FILE="../conf/postgres.conf.prod"

echo "Restoring backup: $BACKUP_FILE"

echo "Target Recovery Time: $RECOVERY_TIME"

# ... (Your extraction logic here) ...

# --- Apply Recovery Settings Dynamically ---
echo "Applying recovery settings..."

# Append dynamic settings to the config
{
    echo "# ===== DYNAMIC RECOVERY (Auto-Generated) ====="
    echo "restore_command = 'cp /var/lib/postgresql/wal_archive/%f %p'"
    echo "recovery_target_time = '$RECOVERY_TIME'"
    echo "recovery_target_action = 'promote'"
    echo "recovery_target_inclusive = 'true'"
} >> "$CONFIG_FILE"
