# 🛠️ Setup Guide

Complete step-by-step guide to set up the Accounting Database System.

---

## 📋 Prerequisites

- **Operating System**: Linux (Ubuntu 20.04+), macOS, or Windows with WSL2
- **Hardware**: Minimum 4GB RAM, 20GB disk space
- **Software**:
  - Docker & Docker Compose
  - Python 3.8+ (for staging scripts)
  - PostgreSQL Client tools (psql, optional)
  - Git

---

## 🚀 Quick Start (5 minutes)

### 1. Clone Repository
```bash
git clone https://github.com/FloranteAtencio/accounting-database.git
cd accounting-database
```

### 2. Configure Environment
```bash
cp .env.example .env
nano .env  # Edit with your credentials
```

### 3. Start Services
```bash
docker-compose -f docker/docker-compose.prod.yaml up -d
```

### 4. Verify Installation
```bash
docker exec erp_postgres psql -U erp_admin -d erp_db -c "SELECT version();"
```

### 5. Load Sample Data
```bash
docker exec -i erp_postgres psql -U erp_admin -d erp_db < temp/data/data_sample.sql
```

✅ **Done!** Your database is ready.

---

## 🐳 Full Installation Guide (Ubuntu)

### Step 1: Update System
```bash
sudo apt update
sudo apt upgrade -y
```

### Step 2: Install Docker

```bash
# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add Docker repository
sudo add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable"

# Install Docker
sudo apt install docker-ce docker-ce-cli containerd.io -y
```

### Step 3: Install Docker Compose
```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
```

### Step 4: Enable and Start Docker
```bash
sudo systemctl enable docker
sudo systemctl start docker

# Add current user to docker group (avoid sudo)
sudo usermod -aG docker $USER
newgrp docker

# Verify docker works
docker ps
```

### Step 5: Create Storage Mount Points (Optional - for SSD/HDD separation)

```bash
# Create mount directories
sudo mkdir -p /mnt/ssd_hot
sudo mkdir -p /mnt/hdd_cold

# Set permissions
sudo chown postgres:postgres /mnt/ssd_hot /mnt/hdd_cold
sudo chmod 700 /mnt/ssd_hot /mnt/hdd_cold

# Mount drives (replace with your actual device paths)
sudo mount /dev/sda1 /mnt/ssd_hot
sudo mount /dev/sdb1 /mnt/hdd_cold

# Make permanent - add to /etc/fstab
sudo nano /etc/fstab
# Add lines:
# /dev/sda1 /mnt/ssd_hot ext4 defaults 0 2
# /dev/sdb1 /mnt/hdd_cold ext4 defaults 0 2
```

### Step 6: Create PostgreSQL Tablespaces (Inside Container)

```bash
docker exec -it erp_postgres psql -U erp_admin -d erp_db
```

```sql
-- Inside PostgreSQL
CREATE TABLESPACE hotspace LOCATION '/mnt/ssd_hot';
CREATE TABLESPACE coldspace LOCATION '/mnt/hdd_cold';

-- Verify
\db
\q
```

### Step 7: Configure Environment Variables

```bash
nano .env
```

```env
# PostgreSQL Configuration
POSTGRES_PASSWORD=YourStrongPassword123!
POSTGRES_DB=erp_db
POSTGRES_USER=erp_admin
POSTGRES_PORT=5432

# Python Staging Scripts
PGHOST=localhost
PGPORT=5432
PGDATABASE=erp_db
PGUSER=erp_admin
PGPASSWORD=YourStrongPassword123!

# Backup Configuration
BACKUP_RETENTION_DAYS=30
BACKUP_PATH=/backups

# System Configuration
LOG_LEVEL=INFO
DEBUG=false
```

---

## 🔒 Security Setup

### 1. Enable Firewall
```bash
sudo apt install ufw -y
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 22/tcp
sudo ufw deny 5432
```
## 🔥1.1 Configure Firewall
```bash\n# Install UFW\nsudo apt install ufw -y\n\n# Enable firewall\nsudo ufw enable\n\n# Allow SSH (IMPORTANT - don't lock yourself out!)\nsudo ufw allow ssh\n\n# Allow PostgreSQL only from localhost (PRODUCTION SECURITY)\nsudo ufw allow from 127.0.0.1 to any port 5432\n\n# Or allow from specific IP\nsudo ufw allow from 192.168.1.0/24 to any port 5432\n\n# Deny all other traffic to PostgreSQL\nsudo ufw deny 5432\n\n# View rules\nsudo ufw status numbered\n```

### 2. Configure PostgreSQL for Remote Access (If needed)

Edit `docker/postgresql.conf`:
```conf
listen_addresses = 'localhost'  # Or specific IP
max_connections = 100
shared_buffers = 256MB
work_mem = 4MB
effective_cache_size = 1GB
```

### 3. Secure Database Users

```bash
docker exec -it erp_postgres psql -U postgres
```

```sql
-- Create application user
CREATE USER app_user WITH PASSWORD 'SecureAppPassword123!';
GRANT CONNECT ON DATABASE erp_db TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO app_user;

-- Create read-only user for reporting
CREATE USER report_user WITH PASSWORD 'ReadOnlyPassword123!';
GRANT CONNECT ON DATABASE erp_db TO report_user;
GRANT USAGE ON SCHEMA public TO report_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO report_user;

-- Verify
\du
```

---

## 📊 Load Schema and Sample Data

### Option 1: Automatic (First Time)
The Docker container automatically loads schemas from `schema/` directory on startup.

### Option 2: Manual Load

```bash
# Load staging schema
docker exec -i erp_postgres psql -U erp_admin -d erp_db < schema/version_1/staging.sql

# Load production schema
docker exec -i erp_postgres psql -U erp_admin -d erp_db < schema/version_1/production.sql

# Load sample data
docker exec -i erp_postgres psql -U erp_admin -d erp_db < temp/data/data_sample.sql

# Verify tables exist
docker exec -it erp_postgres psql -U erp_admin -d erp_db -c "\dt"
```

---

## 🐍 Setup Python Environment (For Staging Scripts)

### 1. Install Python Dependencies

```bash
# Navigate to scripts directory
cd scripts/stage

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Verify Connection

```bash
python3 test_connection.py
```

Expected output:
```
✓ Connected to PostgreSQL
✓ Database: erp_db
✓ User: erp_admin
```

---

## 🔄 Database Operations

### Access PostgreSQL Console

```bash
docker exec -it erp_postgres psql -U erp_admin -d erp_db
```

Common commands:
```sql
-- List databases
\l

-- Connect to database
\c erp_db

-- List tables
\dt

-- List schemas
\dn

-- List functions/procedures
\df

-- Exit
\q
```

### Create New Database (if needed)

```bash
docker exec -it erp_postgres psql -U postgres

CREATE DATABASE new_erp_db;
\q
```

### Reset Database (⚠️ WARNING: Deletes all data)

```bash
docker exec -it erp_postgres psql -U postgres

DROP DATABASE erp_db;
CREATE DATABASE erp_db OWNER erp_admin;
\q

# Reload schema
docker exec -i erp_postgres psql -U erp_admin -d erp_db < schema/version_1/staging.sql
```

---

## 📈 Performance Tuning

### Basic Performance Configuration

```bash
docker exec -it erp_postgres psql -U erp_admin -d erp_db
```

```sql
-- View current settings
SHOW shared_buffers;
SHOW work_mem;
SHOW effective_cache_size;

-- Adjust performance (persistent)
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET work_mem = '4MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';

-- Reload configuration
SELECT pg_reload_conf();

-- Verify
SHOW all;
```

### Create Indexes for Common Queries

```sql
-- Accounts table indexes
CREATE INDEX idx_accounts_client_id ON Finance.accounts(client_id);
CREATE INDEX idx_accounts_account_code ON Finance.accounts(account_code);

-- Transactions table indexes
CREATE INDEX idx_transactions_date ON Finance.transactions(transaction_date);
CREATE INDEX idx_transactions_client ON Finance.transactions(client_id);

-- Verify indexes
\di
```

---

## 🧪 Verification Checklist

After setup, verify everything is working:

```bash
# ✓ Container is running
docker ps | grep erp_postgres

# ✓ Database exists
docker exec erp_postgres psql -U erp_admin -l | grep erp_db

# ✓ Schema exists
docker exec erp_postgres psql -U erp_admin -d erp_db -c "\dn"

# ✓ Tables exist
docker exec erp_postgres psql -U erp_admin -d erp_db -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'Finance';"

# ✓ Python can connect
cd scripts/stage && python3 test_connection.py

# ✓ Backup script works
./scripts/backup.sh

# ✓ Firewall rules active
sudo ufw status
```

---

## 🐛 Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs erp_postgres

# Check if port is in use
sudo netstat -tlnp | grep 5432

# Force rebuild
docker-compose down -v
docker-compose up -d
```

### Connection Refused

```bash
# Verify container is running
docker ps | grep erp_postgres

# Check PostgreSQL is listening
docker exec erp_postgres netstat -tlnp | grep 5432

# Verify credentials in .env
cat .env | grep POSTGRES
```

### Permission Denied Errors

```bash
# Fix Docker permissions
sudo usermod -aG docker $USER
newgrp docker

# Fix file permissions
sudo chown -R $USER:$USER /path/to/database
sudo chmod -R 755 /path/to/database
```

### Schema Not Loading

```bash
# Check if file exists
ls -la schema/version_1/

# Manually load with verbose output
docker exec -it erp_postgres psql -U erp_admin -d erp_db -f schema/version_1/staging.sql

# Check for SQL errors
docker exec -i erp_postgres psql -U erp_admin -d erp_db < schema/version_1/staging.sql 2>&1 | head -50
```

---

## 📚 Next Steps

1. **Read ARCHITECTURE.md** - Understand the system design
2. **Read OPERATIONS.md** - Set up backups and monitoring
3. **Read DEVELOPMENT.md** - Learn how to extend the system
4. **Review Sample Data** - Explore temp/data/ directory
5. **Run Staging Workflow** - Execute scripts/stage/ Python scripts

---

## 📞 Support

For issues:
1. Check the **Troubleshooting** section above
2. Review Docker logs: `docker logs erp_postgres`
3. Check PostgreSQL logs: `docker exec erp_postgres tail -f /var/log/postgresql/postgresql.log`
4. Open an issue on GitHub

