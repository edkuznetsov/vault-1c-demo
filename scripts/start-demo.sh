#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_dir"

if ! command -v docker >/dev/null 2>&1 || ! docker compose version >/dev/null 2>&1; then
  echo "Нужен Docker с Compose v2." >&2
  exit 1
fi

# Читаем только две известные переменные, не выполняя содержимое .env как код.
# Удаляем завершающий CR, чтобы принять .env, созданный в Windows.
if [ -f .env ]; then
  cr=$(printf '\r')
  while IFS= read -r line || [ -n "$line" ]; do
    line=${line%"$cr"}
    case "$line" in
      VAULT_DEMO_ROOT_TOKEN=*) VAULT_DEMO_ROOT_TOKEN=${line#*=} ;;
      DEMO_POSTGRES_PASSWORD=*) DEMO_POSTGRES_PASSWORD=${line#*=} ;;
    esac
  done < .env
fi

new_demo_value() {
  od -An -N16 -tx1 /dev/urandom | tr -d ' \n'
}

if [ -z "${VAULT_DEMO_ROOT_TOKEN:-}" ]; then
  VAULT_DEMO_ROOT_TOKEN=$(new_demo_value)
fi
if [ -z "${DEMO_POSTGRES_PASSWORD:-}" ]; then
  DEMO_POSTGRES_PASSWORD=$(new_demo_value)
fi

umask 077
printf 'VAULT_DEMO_ROOT_TOKEN=%s\nDEMO_POSTGRES_PASSWORD=%s\n' \
  "$VAULT_DEMO_ROOT_TOKEN" "$DEMO_POSTGRES_PASSWORD" > .env
chmod 600 .env
export VAULT_DEMO_ROOT_TOKEN DEMO_POSTGRES_PASSWORD

docker compose up -d --wait --remove-orphans

echo "Запущено три контейнера: PostgreSQL, Vault и Vault Proxy."
echo "PostgreSQL: 127.0.0.1:15432"
echo "Vault:      http://127.0.0.1:8200"
echo "Proxy:      http://127.0.0.1:8100"
echo "Vault UI token: $VAULT_DEMO_ROOT_TOKEN"
