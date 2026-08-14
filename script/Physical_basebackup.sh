#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# --- Configuration ---
BACKUP_DIR="../backup"
LOG_DIR="../log"
LOG_FILE="$LOG_DIR/backup.log"

CONTAINER_NAME="erp_postgres"
DB_USER="erp_admin"
DB_NAME="erp_db"
EXTERNAL_DRIVE="/mnt/external-backup"

RETENTION_DAYS=30

# --- Paths ---
mkdir -p "$BACKUP_DIR"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +%F_%H-%M-%S)
time_start=$(date +%s)  # FIXED: No spaces around '='

TEMP_BACKUP="/tmp/base_${TIMESTAMP}"
BACKUP_NAME="base_backup_${TIMESTAMP}.tar.gz"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

# --- Logging Helper ---
log_msg() {
    echo "[$(date)] $1" >> "$LOG_FILE"
    echo "[$(date)] $1" # Also print to console for debugging
}

log_msg "Backup started"

# --- 1. Start Backup Log in DB ---
# FIXED: Use -c instead of <, and properly escape quotes
BACK_UP_ID=$(docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -t -A -c \
    "SELECT dba_admin.start_backup_log('$DB_NAME', 'FULL', 'PHYSICAL', '$BACKUP_PATH', '15.17');")

if [ -z "$BACK_UP_ID" ]; then
    log_msg "ERROR: Failed to get backup ID from database."
    exit 1
fi

log_msg "Backup ID: $BACK_UP_ID"

# --- 2. Create Physical Base Backup ---
if docker exec "$CONTAINER_NAME" pg_basebackup \
    -D "$TEMP_BACKUP" \
    -Ft \
    -z \
    -P \
    -U "$DB_USER" \
    -Xs; then
    
    log_msg "Base backup created inside container successfully"

    # --- 3. Copy Backup Outside Container ---
    # Ensure the destination directory exists
    mkdir -p "$BACKUP_DIR"
    
    # Copy the TAR file directly (pg_basebackup -Ft creates a .tar file inside the dir)
    # Note: With -Ft, the output is a file named 'base.tar' inside the directory usually, 
    # or the directory itself contains the tar. 
    # If pg_basebackup -Ft creates a file named 'base.tar' inside $TEMP_BACKUP:
    docker cp "$CONTAINER_NAME:$TEMP_BACKUP/base.tar" "$BACKUP_DIR/base_${TIMESTAMP}.tar"
    
    # If it created a directory, we need to tar it again (Your original logic did this)
    # Let's stick to your logic but make it robust:
    # If the above copy failed (because it's a dir), try copying the dir:
    if [ ! -f "$BACKUP_DIR/base_${TIMESTAMP}.tar" ]; then
         docker cp "$CONTAINER_NAME:$TEMP_BACKUP" "$BACKUP_DIR/base_${TIMESTAMP}"
         cd "$BACKUP_DIR"
         tar -czf "$BACKUP_NAME" "base_${TIMESTAMP}"
         rm -rf "base_${TIMESTAMP}"
         cd - > /dev/null
         log_msg "Backup packaged into $BACKUP_NAME"
    else
         # If it was already a file, rename it
         mv "$BACKUP_DIR/base_${TIMESTAMP}.tar" "$BACKUP_PATH"
         log_msg "Backup copied as tar file: $BACKUP_NAME"
    fi

    # --- 4. Cleanup Temp Backup ---
    docker exec "$CONTAINER_NAME" rm -rf "$TEMP_BACKUP"

    # --- 5. Calculate Stats ---
    time_end=$(date +%s)       # FIXED: No spaces
    DURATION_SECOND=$((time_end - time_start)) # FIXED: No spaces, no $ on variables inside $(( ))
    
    if [ -f "$BACKUP_PATH" ]; then
        BACKUP_SIZE=$(du -sh "$BACKUP_PATH" | cut -f1)
    else
        BACKUP_SIZE="0"
    fi

    # --- 6. Update DB Log (SUCCESS) ---
    # FIXED: Use -c and proper quoting
    docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -c \
        "SELECT dba_admin.finish_backup_log($BACK_UP_ID, '$BACKUP_SIZE', $DURATION_SECOND, 'tar.gz', 'SUCCESS');"
        
    log_msg "Base backup successful: Size=$BACKUP_SIZE, Duration=${DURATION_SECOND}s"

else
    log_msg "Base backup FAILED inside container"
    
    # Update DB Log (FAILED)
    docker exec "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -c \
        "SELECT dba_admin.finish_backup_log($BACK_UP_ID, NULL, NULL, NULL, 'FAILED');"
    
    exit 1
fi

# --- 7. Copy to External Storage ---
if mountpoint -q "$EXTERNAL_DRIVE"; then
    cp "$BACKUP_PATH" "$EXTERNAL_DRIVE/"
    log_msg "Backup copied to external storage"
else
    log_msg "WARNING: External storage not mounted. Skipping external copy."
fi

# --- 8. Local Retention Cleanup ---
# Find files older than RETENTION_DAYS and delete them
find "$BACKUP_DIR" \
    -name "base_backup_*.tar.gz" \
    -mtime +$RETENTION_DAYS \
    -delete

log_msg "Backup completed: $BACKUP_NAME"

# #!/bin/bash

# set -e

# BACKUP_DIR="../backup"
# LOG_DIR="../log"
# LOG_FILE="$LOG_DIR/backup.log"

# CONTAINER_NAME="erp_postgres"
# DB_USER="erp_admin"
# DB_NAME="erp_db"
# EXTERNAL_DRIVE="/mnt/external-backup"

# RETENTION_DAYS=30

# mkdir -p "$BACKUP_DIR"
# mkdir -p "$LOG_DIR"

# TIMESTAMP=$(date +%F_%H-%M-%S)
# time_start = $(date +%s)
    
# TEMP_BACKUP="/tmp/base_${TIMESTAMP}"
# BACKUP_NAME="base_backup_${TIMESTAMP}.tar.gz"
# BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

# echo "[$(date)] Backup started" >> "$LOG_FILE"

# # 1. Create physical base backup inside PostgreSQL container
# BACK_UP_ID=$(docker exec "$CONTAINER_NAME" psql -U "$DB_USER"-d "$DB_NAME" < "SELECT dba_admin.start_backup_log('"$DB_NAME"', 'FULL', 'PHYSICAL','"$BACKUP_PATH"','15.17');")

# docker exec "$CONTAINER_NAME" pg_basebackup \
#     -D "$TEMP_BACKUP" \
#     -Ft \
#     -z \
#     -P \
#     -U "$DB_USER" \
#     -Xs

# if [ $? -eq 0 ]; then
#     echo " [$(date)] Baseback up successful " >>  "$LOG_FILE"
#     # 2. Copy backup outside container

#     docker cp \
#         "$CONTAINER_NAME:$TEMP_BACKUP" \
#         "$BACKUP_DIR/base_${TIMESTAMP}"

#     # 3. Remove temporary container backup

#     docker exec "$CONTAINER_NAME" \
#         rm -rf "$TEMP_BACKUP"

#     # 4. Package backup

#     cd "$BACKUP_DIR"

#     tar -czf \
#         "$BACKUP_NAME" \
#         "base_${TIMESTAMP}"

#     rm -rf "base_${TIMESTAMP}"


#     BACKUP_SIZE=$(du -sh $BACKUP_NAME | cut -f1)
#     time_end = $(date +%s)
#     DURATION_SECOND = $(($time_end - $time_start))
#     docker exec "$CONTAINER_NAME" psql -U "$DB_USER"-d "$DB_NAME" < "SELECT dba_admin.finish_backup_log('"$BACK_UP_ID"', '"$BACKUP_SIZE"','"$DURATION_SECOND"','tar.gz', 'SUCCESS');"

# else
#     echo " [$(date)] Baseback up failed " >>  "$LOG_FILE"
#     docker exec "$CONTAINER_NAME" psql -U "$DB_USER"-d "$DB_NAME" < "SELECT dba_admin.finish_backup_log('"$BACK_UP_ID"', NULL, NULL, NULL, 'FAILED');"


# fi


# # 5. Copy to external storage only if actually mounted

# if mountpoint -q "$EXTERNAL_DRIVE"; then

#     cp "$BACKUP_PATH" "$EXTERNAL_DRIVE/"

#     echo "[$(date)] Backup copied to external storage" >> "$LOG_FILE"

# else

#     echo "[$(date)] WARNING: External storage not mounted" >> "$LOG_FILE"

# fi

# # 6. Local retention

# find "$BACKUP_DIR" \
#     -name "base_backup_*.tar.gz" \
#     -mtime +"$RETENTION_DAYS" \
#     -delete

# echo "[$(date)] Backup completed: $BACKUP_NAME" >> "$LOG_FILE"