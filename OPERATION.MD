### Edit crontab

Daily Weekly and Monthly Backup Automation Task 

crontab -e

### Add these lines:

### Daily backup at 2 AM
```bash
0 2 * * * /home/ran/git/erp-database/scripts/backup.sh
```

### Weekly test restore (Sunday at 3 AM)
```bash
0 3 * * 0 /home/ran/git/erp-database/scripts/test-restore.sh
```

### Daily disk check (every morning at 6 AM)
```bash
0 6 * * * /home/ran/git/erp-database/scripts/check-disk.sh
```
### Daily backup alert (every morning at 7 AM)
```bash
0 7 * * * /home/ran/git/erp-database/scripts/backup-alert.sh
```
### Weekly Partition of journals (Every Sunday Morning at 2 AM)
```bash
0 2 * * 0 docker exec -it erp_postgres psql -U erp_admin -d erp_db -c "Select partition_monthly_basis('Finance','journals');"
```
### Monthly Parition of AccountPayables (Every  morning at 2 AM)
```bash
0 2 1 * * docker exec -it erp_postgres psql -U erp_admin -d erp_db -c "Select partition_monthly_basis('Finance','ap_ext');"
```
### Monthly Parition of AccountReceivables (Every  morning at 2 AM)
```bash
0 2 1 * * docker exec -it erp_postgres psql -U erp_admin -d erp_db -c "Select partition_monthly_basis('Finance','ar_ext');"
```
### Monthly Parition of Inventoryaudits (Every  morning at 2 AM)
```bash
0 2 1 * * docker exec -it erp_postgres psql -U erp_admin -d erp_db -c  "Select partition_monthly_basis('Finance','inventory_audits');"
```

# Backup Strategy for Single Server Setup more details backup

## Overview
- **Frequency**: Daily backups
- **Storage**: Internal + External drive
- **Retention**: 30 days
- **Compression**: Gzip
- **Testing**: Weekly restore test
- **Alerts**: Email notifications

## Backup Process
1. `backup.sh` runs daily at 2 AM
2. Creates SQL dump
3. Compresses with gzip
4. Copies to external drive
5. Cleans up old backups (>30 days)

## Restore Process
1. Use `restore.sh <backup-file>`
2. Example: `./restore.sh erp_2026-03-20_02-00-00.sql.gz`

## Test Restore
- Runs weekly on Sundays
- Restores to `test_restore` database
- Verifies data integrity

## Monitoring
- Disk space checked daily
- Backup success alerts sent via email

## Recovery Steps
1. Mount external drive
2. Run `restore.sh` with latest backup
3. Verify data
4. Restart application

---

## 📚 Next Steps

1. **Run Staging Workflow** - Execute scripts/stage/ Python scripts
2. **Read DEVELOPMENT.md** - Learn how to extend the system
---
