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

## Production Deployments

App repositories dispatch the `Deploy app` workflow with an app name and the
exact commit SHA that passed CI. Deployments are queued and run one at a time.
The workflow verifies that the app commit is reachable from its remote `main`,
updates only that submodule pointer on `haum/main`, and deploys the resulting
exact `haum` commit over SSH. Before updating the app checkout or running its
migrations, deployment snapshots all SQLite databases under `data/`, verifies
them, and uploads them using the backup configuration described below. Any
backup or upload failure aborts the deployment.

The workflow requires these GitHub repository variables:

- `DEPLOY_HOST`: production server hostname
- `DEPLOY_USER`: dedicated production deployment user
- `DEPLOY_PATH`: absolute path to the production `haum` checkout
- `DEPLOY_KNOWN_HOSTS`: pinned OpenSSH `known_hosts` entry for the server

It also requires one repository secret:

- `DEPLOY_SSH_KEY`: private half of a dedicated SSH deployment key

Create a GitHub environment named `production` for the deployment job. On the
server, create the deployment user manually, install the matching public key in
its `~/.ssh/authorized_keys`, clone `haum` at `DEPLOY_PATH`, and give the user
access to Docker, its configured `rclone` remote, and ownership of the checkout
and `data/` directory. The workflow never creates or modifies the server
account.

Before enabling the workflow for an existing production checkout, update it
once manually to a `haum` commit containing this version of `scripts/deploy`.
Subsequent runs fetch and select their exact `haum` commit themselves.

Obtain the server's public host key from a trusted channel, verify its fingerprint
directly on the server with
`ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub`, and store a `known_hosts`
line in the form `<host> ssh-ed25519 <base64-key>` in `DEPLOY_KNOWN_HOSTS`. Do
not trust an unverified network scan.

For a manual deployment, open the `Deploy app` workflow in GitHub Actions and
provide the submodule directory name (for example, `bucmarc`) and its full
40-character commit SHA. The same inputs are used by app repository workflows.

The scripts can also be run directly:

```sh
scripts/promote <app> <app-commit-sha>
scripts/deploy <app> <app-commit-sha> [haum-commit-sha]
```

`promote` requires a clean checkout exactly at `origin/main`, creates and
pushes the gitlink commit, and refuses commits outside the app's remote `main`
or commits older than the currently pinned version. `deploy` requires its
requested commit to exactly match the gitlink in the checked-out `haum` commit.
When given a `haum` SHA, it also requires a clean checkout, fetches `origin/main`,
verifies that parent SHA, checks it out detached, and re-executes the pinned
version of itself before deploying.

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
