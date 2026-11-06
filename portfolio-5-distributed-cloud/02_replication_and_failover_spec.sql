-- ============================================================================
-- MIT 8103: Advanced Database Systems
-- Portfolio 5: Production PostgreSQL Streaming Replication Configuration
-- ============================================================================

-- ****************************************************************************
-- 1. PRIMARY SERVER CONFIGURATION (postgresql.conf)
-- ****************************************************************************
/*
# Enable streaming replication WAL logs
wal_level = replica
max_wal_senders = 10
wal_keep_size = 2048MB

# Enforce Synchronous Replication for Zero Data Loss (RPO = 0)
synchronous_commit = on
synchronous_standby_names = 'FIRST 1 (standby_node_1, standby_node_2)'

# Archiving for Point-In-Time-Recovery (PITR) to Cloud Storage (AWS S3)
archive_mode = on
archive_command = 'test ! -f /mnt/cloud_archive/%f && cp %p /mnt/cloud_archive/%f'
*/

-- ****************************************************************************
-- 2. REPLICA / HOT STANDBY CONFIGURATION (postgresql.conf)
-- ****************************************************************************
/*
# Enable read-only queries on standby node
hot_standby = on
hot_standby_feedback = on
max_standby_streaming_delay = 30s
*/

-- ****************************************************************************
-- 3. REPLICATION HEALTH MONITORING QUERIES (Executed on Primary)
-- ****************************************************************************

-- Monitor connected standby replicas and byte lag
SELECT
    client_addr AS replica_ip,
    application_name,
    state,
    sync_state,
    sync_priority,
    pg_wal_lsn_diff(pg_current_wal_lsn(), write_lsn) AS write_lag_bytes,
    pg_wal_lsn_diff(pg_current_wal_lsn(), flush_lsn) AS flush_lag_bytes,
    pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS replay_lag_bytes
FROM pg_stat_replication;
