# haum

Production orchestration root for apps deployed together on the host.

## App Submodules

Applications live under `apps/` as Git submodules. The parent repo pins the exact app commits that should deploy together.

Current apps:

- `apps/bucmarc`
- `apps/grafic`

Add future apps as submodules under `apps/<app-name>` using their canonical Git remote URL.

```sh
git submodule add <git-url> apps/<app-name>
```

After cloning this repo, initialize app checkouts with:

```sh
git submodule update --init --recursive
```

## SQLite Backups

Use `scripts/backup-sqlite-to-gdrive` from cron to snapshot SQLite databases under
`data/` and upload them to Google Drive with `rclone`.

Host requirements:

- `sqlite3`
- `rclone`
- an `rclone` Google Drive remote named `gdrive`

Default behavior:

- source directory: `data/`
- matched files: `*.db`, `*.sqlite`, `*.sqlite3`
- upload destination: `gdrive:haum/sqlite/<timestamp>`
- remote retention: 3 days
- local snapshots: removed after each run

Optional environment overrides:

```sh
HAUM_BACKUP_SOURCE_DIR=/opt/app/data
HAUM_BACKUP_WORK_DIR=/tmp/haum-backups
HAUM_BACKUP_REMOTE=gdrive:haum/sqlite
HAUM_BACKUP_RETENTION_DAYS=3
```

Example cron entry:

```cron
15 3 * * * /opt/app/scripts/backup-sqlite-to-gdrive >> /var/log/haum-backup.log 2>&1
```
