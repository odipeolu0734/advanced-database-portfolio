# Portfolio 5: PostgreSQL Streaming Replication & Connection Pooling Configuration

**Course:** MIT 8103 Advanced Database Systems  
**Case Study:** ShopEase E-Commerce Platform  
**RDBMS:** PostgreSQL 15+ / PgBouncer 1.21+  
**Component:** Production Configuration Scripts & Replication Verification  

---

## 1. Primary Node Configuration (`postgresql.conf`)

The configuration below tunes the PostgreSQL Primary instance for high-throughput Write-Ahead Log (WAL) streaming and synchronous replication to eliminate data loss:

```ini
# ==============================================================================
# SHOPEASE POSTGRESQL 15 PRIMARY CONFIGURATION
# Location: /var/lib/postgresql/data/postgresql.conf
# ==============================================================================

# ------------------------------------------------------------------------------
# CONNECTIONS & NETWORKING
# ------------------------------------------------------------------------------
listen_addresses = '*'                  # Accept connections from internal VPC
port = 5432
max_connections = 300                   # Fronted by PgBouncer (150 active pooled)
superuser_reserved_connections = 5

# ------------------------------------------------------------------------------
# MEMORY & RESOURCE TUNING
# ------------------------------------------------------------------------------
shared_buffers = 16GB                   # 25% of 64GB System RAM
effective_cache_size = 48GB             # 75% of System RAM
work_mem = 64MB                         # Prevents disk-spilling during complex joins
maintenance_work_mem = 2GB              # Accelerates vacuuming and index builds

# ------------------------------------------------------------------------------
# WRITE-AHEAD LOGGING (WAL) & REPLICATION
# ------------------------------------------------------------------------------
wal_level = replica                     # Enables archiving and streaming replication
max_wal_size = 16GB
min_wal_size = 2GB
checkpoint_completion_target = 0.9      # Smooths checkpoint disk I/O spikes
checkpoint_timeout = 15min

# Streaming Replication Workers
max_wal_senders = 10                    # Maximum concurrent standby replica connections
max_replication_slots = 10              # Retains WAL until acknowledged by replicas
wal_keep_size = 8GB                     # Retains buffer if standby falls behind temporarily

# Synchronous Replication Mode (Zero RPO)
# 'FIRST 1' guarantees at least one local standby has flushed WAL to disk
synchronous_commit = on
synchronous_standby_names = 'FIRST 1 (pg_standby_az_b, pg_standby_az_c)'

# ------------------------------------------------------------------------------
# CONTINUOUS WAL ARCHIVING (FOR POINT-IN-TIME RECOVERY TO S3)
# ------------------------------------------------------------------------------
archive_mode = on
archive_command = 'aws s3 cp %p s3://shopease-prod-wal-archive/%f'
archive_timeout = 300                   # Force WAL segment switch every 5 minutes
```

---

## 2. Authentication Rules (`pg_hba.conf`)

Controls which instances and roles are permitted to stream WAL records:

```text
# ==============================================================================
# SHOPEASE HOST-BASED AUTHENTICATION (pg_hba.conf)
# Location: /var/lib/postgresql/data/pg_hba.conf
# ==============================================================================

# TYPE  DATABASE        USER            ADDRESS                 METHOD

# Local administrative access
local   all             postgres                                peer

# Application access via PgBouncer private subnet
host    shopease        shopease_app    10.0.10.0/24            scram-sha-256

# Streaming Replication from authorized Standby nodes
host    replication     replicator      10.0.20.0/24            scram-sha-256
```

---

## 3. Standby Node Configuration

On the standby node, PostgreSQL is initialized from a base backup and placed into standby recovery mode.

### 3.1 Initializing the Replica via `pg_basebackup`
```bash
# Executed on Standby Node to copy data cluster from Primary
pg_basebackup -h 10.0.20.10 -p 5432 -U replicator -D /var/lib/postgresql/data \
              -Fp -Xs -P -R --slot=standby_az_b_slot
```
*(The `-R` flag automatically generates `standby.signal` and configures `primary_conninfo`)*.

### 3.2 Standby Configuration Directives (`postgresql.conf` on Standby)
```ini
# Enable read-only analytical queries while receiving replication stream
hot_standby = on
max_standby_streaming_delay = 30s       # Avoids canceling long BI queries prematurely
hot_standby_feedback = on               # Prevents vacuum on primary from pruning rows needed by standby
primary_conninfo = 'host=10.0.20.10 port=5432 user=replicator application_name=pg_standby_az_b password=SecureSecret123!'
primary_slot_name = 'standby_az_b_slot'
```

---

## 4. Connection Pooling Configuration (`pgbouncer.ini`)

PgBouncer multiplexes thousands of lightweight microservice connections into a controlled set of server connections:

```ini
[databases]
shopease = host=127.0.0.1 port=5432 dbname=shopease pool_size=100
shopease_ro = host=10.0.20.20 port=5432 dbname=shopease pool_size=50

[pgbouncer]
logfile = /var/log/postgresql/pgbouncer.log
pidfile = /var/run/postgresql/pgbouncer.pid
listen_addr = 0.0.0.0
listen_port = 6432
auth_type = scram-sha-256
auth_file = /etc/pgbouncer/userlist.txt

# Pooling mode: Transaction mode provides the highest efficiency
pool_mode = transaction

# Connection limits
max_client_conn = 10000
default_pool_size = 50
min_pool_size = 10
reserve_pool_size = 15
reserve_pool_timeout = 5

# Timeouts
server_idle_timeout = 600
client_idle_timeout = 300
query_timeout = 120
```

---

## 5. Replication Monitoring & Verification Queries

### 5.1 Verification on Primary: Inspect Active Replication Streams
```sql
SELECT 
    application_name,
    client_addr,
    state,
    sync_state,
    sync_priority,
    pg_wal_lsn_diff(pg_current_wal_lsn(), write_lsn) AS write_lag_bytes,
    pg_wal_lsn_diff(pg_current_wal_lsn(), flush_lsn) AS flush_lag_bytes,
    pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS replay_lag_bytes,
    reply_time
FROM pg_stat_replication;
```

**Expected Production Output:**
```text
 application_name | client_addr | state     | sync_state | sync_priority | write_lag_bytes | flush_lag_bytes | replay_lag_bytes |          reply_time          
------------------+-------------+-----------+------------+---------------+-----------------+-----------------+------------------+------------------------------
 pg_standby_az_b  | 10.0.20.20  | streaming | sync       |             1 |               0 |               0 |                0 | 2026-03-15 15:40:12.891+00
 pg_standby_az_c  | 10.0.20.21  | streaming | potential  |             2 |               0 |               0 |             1024 | 2026-03-15 15:40:12.880+00
```
*Analysis:* `pg_standby_az_b` is operating in strict synchronous (`sync`) mode with 0 bytes of flush lag, verifying zero data loss (RPO = 0).

### 5.2 Verification on Standby: Confirm Recovery Status
```sql
-- Returns TRUE if the node is currently in read-only recovery
SELECT pg_is_in_recovery();

-- Displays the last WAL position received and replayed
SELECT 
    pg_last_wal_receive_lsn() AS receive_lsn,
    pg_last_wal_replay_lsn() AS replay_lsn,
    pg_last_xact_replay_timestamp() AS last_transaction_time;
```
