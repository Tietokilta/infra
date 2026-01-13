# Centralized Backup System for Tietokilta Infrastructure

## Overview

A backup system running on the NixOS VM (tikpannu/pannu.tietokilta.fi) that backs up all services to a mounted Hetzner Storage Box, with automated recovery tests.

**Target:** Hetzner Storage Box mounted via CIFS/SFTP
**Retention:** 7 daily + 4 weekly

## Data Sources (Dynamic Discovery)

| Source | Discovery Method | Schedule |
|--------|-----------------|----------|
| Azure PostgreSQL | Query `pg_database` for all non-system DBs | Daily 02:00 |
| Azure MySQL | Query `SHOW DATABASES` for all non-system DBs | Daily 02:30 |
| Azure Blob/Files | `az storage account list` + enumerate containers/shares | Weekly Sunday |
| MongoDB Atlas | `mongodump` (backs up all DBs automatically) | Daily 03:00 |
| Discourse | Local `pg_dump` of discourse database | Daily 03:30 |

**Benefits of dynamic discovery:**
- New databases/storage accounts are automatically included
- No manual config updates when services are added/removed
- Self-documenting backup coverage

## Architecture

```
tikpannu (NixOS VM)
    │
    ├── /mnt/backup (Hetzner Storage Box mounted via CIFS or SFTP/SSHFS)
    │
    ├── systemd timers (scheduling)
    │
    ├── Pre-backup scripts
    │   ├── pg_dump (Azure PostgreSQL, Discourse)
    │   ├── mysqldump (Azure MySQL)
    │   ├── mongodump (MongoDB Atlas)
    │   └── rclone sync (Azure Blob/File storage)
    │
    └── restic backup → /mnt/backup/restic-repo
```

### Storage Box Mount (CIFS/SMB)

```nix
# modules/backup/storagebox.nix
fileSystems."/mnt/backup" = {
  device = "//uXXXXXX.your-storagebox.de/backup";
  fsType = "cifs";
  options = [
    "credentials=${config.sops.secrets.storagebox-credentials.path}"
    "uid=root"
    "gid=root"
    "_netdev"
    "x-systemd.automount"
    "x-systemd.idle-timeout=60"
  ];
};

# Required package
environment.systemPackages = [ pkgs.cifs-utils ];
```

## Module Structure

```
tikpannu-nixos-config/
  modules/
    backup/
      default.nix           # Main module, imports all
      secrets.nix           # sops-nix secret declarations
      storagebox.nix        # Hetzner Storage Box mount
      azure-postgres.nix    # Azure PostgreSQL backup
      azure-mysql.nix       # Azure MySQL (TikJob Ghost)
      azure-storage.nix     # Azure Blob + File Shares
      mongodb.nix           # MongoDB Atlas backup
      discourse.nix         # Local Discourse PostgreSQL
    secrets/
      backup.yaml           # Encrypted credentials (new)
  tests/
    backup/
      default.nix           # Test suite entry
      postgres-backup.nix   # PostgreSQL backup/restore test
      full-restore.nix      # End-to-end restore test
```

## Implementation Steps

### Phase 1: Storage Box Mount + Module Foundation

1. Create `modules/backup/storagebox.nix` for Hetzner Storage Box mount:
   ```nix
   fileSystems."/mnt/backup" = {
     device = "//uXXXXXX.your-storagebox.de/backup";
     fsType = "cifs";
     options = [
       "credentials=${config.sops.secrets.storagebox-credentials.path}"
       "uid=root" "gid=root" "_netdev" "x-systemd.automount"
     ];
   };
   ```

2. Create `modules/backup/default.nix` with options:
   ```nix
   services.tik-backup = {
     enable = mkEnableOption "Tietokilta backup";
     backupPath = mkOption {
       type = types.str;
       default = "/mnt/backup/restic-repo";
     };
     # per-source enable flags
   };
   ```

3. Create `modules/backup/secrets.nix` declaring sops secrets:
   - `storagebox-credentials` (CIFS username/password file)
   - `backup-restic-password`
   - `backup-azure-client-id` (Service Principal for dynamic Azure access)
   - `backup-azure-client-secret`
   - `backup-azure-tenant-id`
   - `backup-azure-postgres-password`
   - `backup-azure-mysql-password`
   - `backup-mongodb-connection-string`
   - `backup-alerting-webhook-url`

4. Create `modules/secrets/backup.yaml` encrypted with sops

5. Add backup module to `modules/default.nix` imports

### Phase 2: Database Backups (Dynamic Discovery)

6. **Azure PostgreSQL** (`azure-postgres.nix`):
   ```bash
   # Dynamic discovery - enumerate ALL databases at backup time
   # Excludes system databases automatically
   DATABASES=$(PGPASSWORD="$PG_PASS" psql -h "$PG_HOST" -U "$PG_USER" -d postgres -t -c \
     "SELECT datname FROM pg_database
      WHERE datistemplate = false
      AND datname NOT IN ('postgres', 'azure_maintenance', 'azure_sys');")

   for db in $DATABASES; do
     pg_dump -h "$PG_HOST" -U "$PG_USER" -d "$db" \
       --format=custom -f "/var/backup/postgres/$db.dump"
   done
   ```
   ```nix
   timerConfig.OnCalendar = "02:00";
   pruneOpts = [ "--keep-daily 7" "--keep-weekly 4" ];
   ```

7. **Azure MySQL** (`azure-mysql.nix`):
   ```bash
   # Dynamic discovery - enumerate ALL databases
   DATABASES=$(mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASS" -N -e \
     "SHOW DATABASES WHERE \`Database\` NOT IN
      ('information_schema', 'mysql', 'performance_schema', 'sys');")

   for db in $DATABASES; do
     mysqldump -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASS" \
       --single-transaction "$db" > "/var/backup/mysql/$db.sql"
   done
   ```
   ```nix
   timerConfig.OnCalendar = "02:30";
   ```

8. **MongoDB Atlas** (`mongodb.nix`):
   ```bash
   # mongodump backs up ALL databases by default
   mongodump --uri="$MONGODB_CONNECTION_STRING" --out="/var/backup/mongodb" --gzip
   ```
   ```nix
   timerConfig.OnCalendar = "03:00";
   ```

9. **Discourse** (`discourse.nix`):
   ```nix
   # pg_dump local discourse database
   timerConfig.OnCalendar = "03:30";
   ```

### Phase 3: Storage Backups (Dynamic Discovery)

10. **Azure Blob/File Storage** (`azure-storage.nix`):
    ```bash
    # Dynamic discovery using Azure CLI with Service Principal
    # Requires: azure-sp-credentials secret (client_id, client_secret, tenant_id)
    az login --service-principal -u "$AZURE_CLIENT_ID" -p "$AZURE_CLIENT_SECRET" --tenant "$AZURE_TENANT_ID"

    # Get ALL storage accounts (exclude terraform state bucket)
    STORAGE_ACCOUNTS=$(az storage account list --query "[?name!='tikprodterraform'].name" -o tsv)

    for sa in $STORAGE_ACCOUNTS; do
      echo "Backing up storage account: $sa"
      KEY=$(az storage account keys list --account-name "$sa" --query "[0].value" -o tsv)

      # Backup ALL blob containers
      CONTAINERS=$(az storage container list --account-name "$sa" --account-key "$KEY" --query "[].name" -o tsv)
      for container in $CONTAINERS; do
        mkdir -p "/var/backup/azure-blob/$sa/$container"
        az storage blob download-batch \
          -d "/var/backup/azure-blob/$sa/$container" \
          -s "$container" --account-name "$sa" --account-key "$KEY"
      done

      # Backup ALL file shares
      SHARES=$(az storage share list --account-name "$sa" --account-key "$KEY" --query "[].name" -o tsv 2>/dev/null || true)
      for share in $SHARES; do
        mkdir -p "/var/backup/azure-files/$sa/$share"
        az storage file download-batch \
          -d "/var/backup/azure-files/$sa/$share" \
          -s "$share" --account-name "$sa" --account-key "$KEY"
      done
    done
    ```
    ```nix
    timerConfig.OnCalendar = "Sun 04:00";
    ```

### Phase 4: Alerting

11. Add failure notifications:
    ```nix
    services.restic.backups.<name>.backupCleanupCommand = ''
      if [ $? -ne 0 ]; then
        curl -X POST -d '{"text":"Backup failed"}' "$WEBHOOK_URL"
      fi
    '';
    ```

### Phase 5: Testing Infrastructure

12. Create test base config (`tests/backup/base-backup-test.nix`):
    - Mock credentials via `lib.mkForce`
    - Disable real Azure connections

13. Create multi-VM test (`tests/backup/postgres-backup.nix`):
    ```nix
    nodes = {
      pannu = { /* backup agent with mock config */ };
      storage = { services.minio.enable = true; };  # S3 mock
      database = { services.postgresql.enable = true; };  # DB mock
    };

    testScript = ''
      # Test backup runs
      # Test restore works
      # Verify data integrity
    '';
    ```

14. Add tests to `tests/default.nix`:
    ```nix
    backup-postgres = runTest ./backup/postgres-backup.nix;
    backup-restore = runTest ./backup/full-restore.nix;
    ```

### Phase 6: Recovery Runbook

15. Create `docs/recovery-runbook.md` with:
    - Emergency contacts
    - Prerequisites (tools, access)
    - Step-by-step recovery for each data source
    - Verification procedures
    - Testing schedule (monthly restore drills)

## Required Secrets

Create `modules/secrets/backup.yaml` with these keys:

```yaml
# Hetzner Storage Box (CIFS credentials file format)
# Format: username=uXXXXXX\npassword=YOUR_PASSWORD
storagebox-credentials: <encrypted>

# Restic encryption
restic-password: <encrypted>

# Azure Service Principal (for dynamic storage discovery)
# This SP needs "Storage Account Key Operator" and "Reader" roles
azure-client-id: <encrypted>
azure-client-secret: <encrypted>
azure-tenant-id: <encrypted>

# Azure PostgreSQL (host can be discovered via az cli, but password needed)
azure-postgres-admin-password: <encrypted>

# Azure MySQL
azure-mysql-password: <encrypted>

# MongoDB Atlas
mongodb-connection-string: <encrypted>

# Alerting
alerting-webhook-url: <encrypted>
```

**Note:** No hardcoded storage account keys - the backup script uses Azure Service Principal
to dynamically discover and access all storage accounts at runtime.

## Critical Files to Modify

| File | Change |
|------|--------|
| `tikpannu-nixos-config/modules/default.nix` | Add `./backup` import |
| `tikpannu-nixos-config/.sops.yaml` | Add `secrets/backup.yaml` path |
| `tikpannu-nixos-config/tests/default.nix` | Add backup tests |
| `tikpannu-nixos-config/modules/test-vm.nix` | Add backup mock overrides |

## Critical Files to Read Before Implementation

- `tikpannu-nixos-config/modules/tikbots/tikbot.nix` - sops.templates pattern
- `tikpannu-nixos-config/modules/secrets/sops.nix` - sops-nix setup
- `tikpannu-nixos-config/tests/base-pannu-config.nix` - test mock pattern
- `tikpannu-nixos-config/tests/server-up.nix` - multi-VM test pattern
- `modules/common/main.tf` - PostgreSQL server config

## Backup Consistency Strategies

| Source | Strategy |
|--------|----------|
| PostgreSQL | `pg_dump --serializable-deferrable` |
| MySQL | `mysqldump --single-transaction` |
| MongoDB | `mongodump` (uses oplog for consistency) |
| Blob Storage | Static files, eventual consistency acceptable |
| File Shares | Azure snapshot before rclone sync |

## Test Plan

**Automated (CI via NixOS VM tests):**
- Storage Box mount works (mock with tmpfs in tests)
- Backup service starts correctly
- Restic repository initializes on local path
- Backup files created with expected structure
- Restore to mock database succeeds
- `restic check` passes
- Retention policy prunes correctly

**Manual (Runbook):**
- Real Azure database connectivity
- Real Hetzner Storage Box mount
- Production data volume handling
- Full disaster recovery drill (quarterly)

**Test Simplification (vs S3):**
Using a mounted storage box simplifies testing - we can mock it with a local tmpfs directory in NixOS VM tests instead of needing a MinIO S3 mock service.
