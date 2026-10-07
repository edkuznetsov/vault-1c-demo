#!/bin/sh
set -eu

chown vault:vault /runtime/proxy
rm -f /runtime/proxy/role-id /runtime/proxy/secret-id /runtime/proxy/ready

su-exec vault vault server -dev &
vault_pid=$!

stop_vault() {
  kill -TERM "$vault_pid" 2>/dev/null || true
  wait "$vault_pid" 2>/dev/null || true
}

trap stop_vault INT TERM

until vault status >/dev/null 2>&1; do
  if ! kill -0 "$vault_pid" 2>/dev/null; then
    wait "$vault_pid"
    exit $?
  fi
  sleep 1
done

if ! /config/bootstrap.sh; then
  stop_vault
  exit 1
fi

wait "$vault_pid"
