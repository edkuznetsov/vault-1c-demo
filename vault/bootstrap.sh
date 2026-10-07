#!/bin/sh
# This script is bind-mounted into Linux containers and requires LF endings.
set -eu

if ! vault secrets list -format=json | grep -q '"secret/"'; then
  vault secrets enable -path=secret kv-v2 >/dev/null
fi

vault kv put secret/onec/database \
  host="127.0.0.1" \
  port="15432" \
  database="demo_db" \
  username="demo_user" \
  password="$DEMO_POSTGRES_PASSWORD" >/dev/null

vault policy write onec-policy /config/policies/onec-policy.hcl >/dev/null

vault auth enable jwt >/dev/null 2>&1 || true
vault write auth/jwt/config \
  jwt_validation_pubkeys="$(cat /runtime/keys/public.pem)" \
  bound_issuer="onec" >/dev/null
vault write auth/jwt/role/onec-demo @/config/roles/jwt-onec-demo.json >/dev/null

vault auth enable approle >/dev/null 2>&1 || true
vault write auth/approle/role/onec-proxy \
  token_policies="onec-policy" \
  secret_id_ttl="24h" \
  token_ttl="5m" \
  token_max_ttl="30m" >/dev/null

vault read -field=role_id auth/approle/role/onec-proxy/role-id \
  > /runtime/proxy/role-id
vault write -field=secret_id -f auth/approle/role/onec-proxy/secret-id \
  > /runtime/proxy/secret-id

chmod 600 /runtime/proxy/role-id /runtime/proxy/secret-id
chown vault:vault /runtime/proxy/role-id /runtime/proxy/secret-id
touch /runtime/proxy/ready
chown vault:vault /runtime/proxy/ready

echo "Vault demo configuration is ready."
