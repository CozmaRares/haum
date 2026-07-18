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
