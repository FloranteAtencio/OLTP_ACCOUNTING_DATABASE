# 🧠 Accounting Database System (PostgreSQL)

A modular **Accounting database system** designed to handle inventory, sales, and financial transactions and more using PostgreSQL.

---

## 🚀 Features

* 📦 **Inventory Management**

  * Tracks stock movement across warehouses
  * Supports purchases, sales, transfers, and returns
  * Inventory cost flow (LIFO, FIFO, AVCO)

* 💰 **Accounting System**

  * Double-entry bookkeeping (Debit/Credit)
  * Automatic journal entry generation

* 🧾 **Accounts Receivable / Payable**

  * Tracks customer balances and supplier obligations
  * Supports payment status and due dates

* 🥞 **Multitenant client and Chart of Account**

  * Multiple Clients can simultaneously operate 
  * Multiple Chart of account custom made for every Clients needs


* ⚙️ **Stored Procedures (PL/pgSQL)**

  * Centralized transaction processing
  * Modular design (Inventory + Accounting modules)

* 🧩 **Partitioned Tables**

  * Scalable handling of financial data using date-based partitioning

* 📊 **Reporting & Dashboard Queries**

  * Inventory levels
  * Revenue and profit
  * Aging reports (AR/AP)

* 🫆 **Audit Logs / Extended Audit Logs**

  * Audit Hash Code Chain
  * Automatic Recording Every Transaction
  * Summary Import Logs

* 📋 **Audit Trail**
 
  * Transaction Life Cycle
  * Import Session

* 📝 **Compliance**
  
  * Compliance log
  * import compliance log

* 🗂 **Staging**
  
   * Data Testing
   * Sanitation
   * Validation
   * Approval
    
* 🛡️ **Trigger Guard**

   * Prevent direct operation to table
   * Need specific setting to perform CRUD Operations

---

## 🏗️ System Architecture

```
[CSV, API, SPREAD_SHEET_IMPORT]
      ↓
[Staging] -> [Record Lineage]
      ↓
[Sanitation] 
      ↓
[Validations] -> [Record Lineage]
      ↓
[Approval Chain] -> [Record Lineage]
      ↓
[Posting] -> [Record Lineage]
      ↓
[ AR / AP / Inventory Transactions and so on] -> [Audit Log]
      ↓
[Journals] -> [Audit Log]
      ↓
[Accounting Module/Inventory Module] -> [Audit Log]
      ↓
[Lineage] 

```

---

## 🧠 Key Concepts Demonstrated

* Relational Database Design (Normalization, Constraints)
* Partitioning Strategy (Range Partitioning by Date)
* Composite Keys in Partitioned Tables
* Foreign Key Integrity across modules
* Financial Data Modeling (ERP-style logic)
* Query Optimization using Indexes
* Modular Stored Procedure Design
* Audit Log for Every Table CRUD Operations
* Recording Data Lineage (From Staging to Production)
* Idempotency key for tracking
* Code Hashing Chain
* Sanitation, Validation and Approval Chain at Staging 
---

## 🛠️ Tech Stack

* **Database:** PostgreSQL
* **Language:** SQL / PLpgSQL
* **Tools:** pgAdmin / DBeaver (optional)

## 💼 Business Value

This system simulates a real Accounting backend where:

* Inventory transactions automatically affect financial records
* Sales generate accounts receivable
* Purchases generate accounts payable
* Financial reports can be derived from journal entries
* Record Data Lineage From Staging to Production to Archive
* Multiple Tenant and custom made Chart of Account
* Record Operations Logs with Hash Chain
* Idempotency key to prevent duplicate process
* Staging area (Sanitation, Validations and Approval) Before posting to productions table
* Compliance log (for every successful and failure transactions)
* Import log (Record every successful and failure import transaction)
* Guard any data from direct transaction to void by passing the process
* Transaction Lifecycle data tracking inside production schema
  
---


---
# Auditing And Trigger

---
## Purpose
  * Track every changes or before it happened
  * Record Every changes for auditing purposes
  * To prevent directly operation to the table

---
## Challenges
  * By passing the process by direct transaction to the table
  * Tracking of who, when, and what operations happened to data
  * History logs data

---
## Resolve
  * Core Finance tables are protected against direct data manipulation. Business operations are executed exclusively through stored procedures. Database-level controls ensure that audit logging, lineage recording, compliance validation, and workflow management cannot be bypassed
---

# Flexible charts

---
## Goal
  * Purpose is for multiple tenant of clients that has unique set of charts of account. This is will help us to distinct identify each client financial records and their own format of accounts.


---
## Resolve
  * This update helps me from break my code with different accountcode and account base on our clients norms.With the help of this update we can assign and identify which account has role to use specific use for (Account Receivables, Account Payables Revenue and so on.)

---
## Challenges
  * This update changes 20% of the version 1 and added. Tables added and modify some of tables for clients to be able distinctly identify. Business logic this make multiple changes due inorder to adapt to the new update.

# Staging 

---
## Purpose
  * Ensure a consistent data and uncorrupted data as possible.
  * Built for ground testing of data to sanitate validate and seek for approval of the higher positions before posting to production schema. 

---
## Challenges
  * A lot of data where bouncing back, corrupted data and inconsistent data.
  * Not all data are suitable to under go staging they are directly load at production schema.  
  * Every import Transactions should be log and compliance log should be record (success and fail)
  * Every stage should be log too
    
---
## Resolve
  * Create process to catch early inconsistent data to avoid corrupted data before they enter the production schema through sanitation, validation and approval. 
  * Data source file and every data are log for every successful and fail transaction for import session log
  * Data that are not suitable for staging schema will be log at lineage table for tracking (expecting all the data are consistent)
---

# DISCLAIMER 
  * In this repo I focus only at Account Receivable only! make sure you have python  and with psycopg2 python extensions installed
# TO Use it
  * Staging schema tables and object are at schema/version_1 SQL script with name of 'Staging'
  * Python script and sample Data are at /script/stage
  * Just run the python script in order from import to sanitation to validation to approval to posting 
---
## 🚀 Environment Setup (Ubuntu)

### 🔄 Update System

```bash
sudo apt update
sudo apt upgrade -y
```

## 🐳 Install Docker

```bash
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable"

sudo apt install docker-ce docker-ce-cli containerd.io -y
```

## Install Docker Composer
```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose
```

### ▶️ Enable Docker
```bash
sudo systemctl enable docker
sudo systemctl start docker

sudo usermod -aG docker $USER
newgrp docker
```
### 📁 Create Mount Points
```bash
sudo mkdir /mnt/ssd_hot
sudo mkdir /mnt/hdd_cold
sudo chown postgres:postgres /mnt/ssd_hot /mnt/hdd_cold
sudo chmod 700 /mnt/ssd_hot /mnt/hdd_cold
```

### 🔗 Mount Drives
```bash
mount {ssd_location} /mnt/ssd_hot
mount {hdd_location} /mnt/hdd_cold
```

### 🧠 Create Tablespaces

Inside container:

```sql
CREATE TABLESPACE hotspace LOCATION '/mnt/ssd_hot';
CREATE TABLESPACE coldspace LOCATION '/mnt/hdd_cold';
```


### 🔥 Fire wall 🔥
```bash

sudo apt install ufw

sudo ufw enable
sudo ufw allow ssh
sudo ufw deny 5432
```

### 🔐 Use Environment File (DON’T hardcode passwords)
Create .env file:
```bash
nano .env
```

```bash
POSTGRES_PASSWORD=StrongPassword123!
POSTGRES_DB=erp_db
POSTGRES_USER=erp_admin
```

### 💾 Backup Setup (DO THIS NOW)

Create backup script:
```bash
nano backup.sh
```

```bash
#!/bin/bash
docker exec erp_postgres pg_dump -U erp_admin erp_db > /backup/erp_$(date +%F).sql
```
#### Make executable:
```bash
chmod +x backup.sh
```

#### Schedule daily backup:
```bash
crontab -e
```
Add:
```bash
7 2 * * * ~/git/Prod-database/backup.sh
```

### 🔐 Access PostgreSQL
```bash
docker exec -it erp_postgres psql -U erp_admin -d erp_db
```

Basic Performance Config Inside container:
```bash
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET work_mem = '4MB';
SELECT pg_reload_conf();
```

### Some Helpful Debuging commands

let's debug this systematically. Run these commands:

1. Check if container is running
```bash
docker ps | grep erp_postgres
```
2. Check initialization logs
```bash
docker logs erp_postgres
```
Look for error messages or initialization output.
3. Verify volume is mounted correctly
```bash
docker exec erp_postgres ls -la /docker-entrypoint-initdb.d/
Should show your .sql files.
```
4. Check if database was created
```bash
docker exec erp_postgres psql -U postgres -l
Should list erp_db if initialization ran.
```
5. Force fresh initialization
```bash
docker-compose down -v
docker-compose up -d
docker logs erp_postgres
```
6. docker compose <yaml is at docker/>
```bash
docker composer -f docker/docker-composer.prod.yaml up
```
### Use sample data at tmp/data
```bash
  docker exec -i erp_postgres psql -U erp_admin -d erp_db < temp/data/data_sample.sql
```

### Edit crontab
crontab -e

### Add these lines:

### Daily backup at 2 AM
0 2 * * * /home/ran/git/erp-database/scripts/backup.sh

### Weekly test restore (Sunday at 3 AM)
0 3 * * 0 /home/ran/git/erp-database/scripts/test-restore.sh

### Daily disk check (every morning at 6 AM)
0 6 * * * /home/ran/git/erp-database/scripts/check-disk.sh

### Daily backup alert (every morning at 7 AM)
0 7 * * * /home/ran/git/erp-database/scripts/backup-alert.sh

### Weekly Partition of journals (Every Sunday Morning at 2 AM)
0 2 * * 0 docker exec -it erp_postgres psql -U erp_admin -d erp_db -c "Select partition_monthly_basis('Finance','journals');"

### Monthly Parition of AccountPayables (Every  morning at 2 AM)
0 2 1 * * docker exec -it erp_postgres psql -U erp_admin -d erp_db -c "Select partition_monthly_basis('Finance','ap_ext');"

### Monthly Parition of AccountReceivables (Every  morning at 2 AM)
0 2 1 * * docker exec -it erp_postgres psql -U erp_admin -d erp_db -c "Select partition_monthly_basis('Finance','ar_ext');"

### Monthly Parition of Inventoryaudits (Every  morning at 2 AM)
0 2 1 * * docker exec -it erp_postgres psql -U erp_admin -d erp_db -c  "Select partition_monthly_basis('Finance','inventory_audits');"

# Backup Strategy for Single Server Setup

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


## 📌 Future Improvements

* High Availability (HA)
* Disaster Recovery (DR)
* Logical replication
* Backup strategies
* Query tuning with EXPLAIN ANALYZE
* PostgreSQL extensions
* Row-Level Security (RLS)
* Database migrations
* CI/CD for database deployments
* Performance benchmarking
* Monitoring with tools like pg_stat_statements
* Event-driven architectures and messaging
* Archiving
---
