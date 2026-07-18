#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

if [[ -n "$(git status --porcelain)" ]]; then
    echo "Refusing to deploy from a dirty parent checkout."
    echo "Commit or stash changes in this repo before running deploy."
    exit 1
fi

echo "==> Pulling latest production state..."
git pull --ff-only origin main

echo "==> Updating app submodules..."
git submodule update --init --recursive

echo "==> Preparing persistent data directories..."
mkdir -p data/bucmarc data/grafic

echo "==> Ensuring reverse-proxy network exists..."
docker network inspect reverse-proxy >/dev/null 2>&1 ||
    docker network create reverse-proxy

echo "==> Building and starting bucmarc..."
BUCMARC_DATA_DIR="$root/data/bucmarc" \
    docker compose -p bucmarc -f apps/bucmarc/compose.yaml up -d --build

echo "==> Building and starting grafic..."
GRAFIC_DATA_DIR="$root/data/grafic" \
    docker compose -p grafic -f apps/grafic/compose.yaml up -d --build

echo "==> Starting proxy..."
docker compose -p proxy -f compose.yaml up -d

echo "==> Service status:"
docker compose -p bucmarc -f apps/bucmarc/compose.yaml ps
docker compose -p grafic -f apps/grafic/compose.yaml ps
docker compose -p proxy -f compose.yaml ps
