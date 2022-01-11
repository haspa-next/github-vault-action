#!/bin/bash

source /scripts/vault-env.sh

SERVICE=$1
ENV=$2

if [ -z "$SERVICE" ]; then
	echo "Usage: create-role.sh <rolename>"
	exit 1
fi

if [ -z "$VAULT_ADDR" ]; then
	echo "Vault address must be set in VAULT_ADDR"
	exit 1
fi

if [ -z "$VAULT_TOKEN" ]; then
	echo "Vault token must be set in VAULT_TOKEN"
	exit 1
fi

if [ -z "$ENV" ]; then
	ENV="stage"
fi

vault token renew

vault read auth/approle/role/service-$SERVICE-$ENV &> /dev/null
if [ "$?" -eq "0" ]; then
	echo "Role for $SERVICE-$ENV already exists"
	exit 0
fi

# Create policy for the service to read its own secrets
cat << EOF > ./tmp-policy-service.hcl
path "secret/service/$SERVICE/$ENV" {
	capabilities = ["read"]
}
EOF
vault policy write service-$SERVICE-$ENV tmp-policy-service.hcl
rm tmp-policy-service.hcl

# Create an app role for the service
vault write auth/approle/role/service-$SERVICE-$ENV role_name=$SERVICE-$ENV policies=service-base policies=service-$SERVICE-$ENV secret_id_num_uses=0 secret_id_ttl=0 period=2764800 token_ttl=31536000 token_max_ttl=0
vault write auth/approle/role/service-$SERVICE-$ENV/role-id role_id=service-$SERVICE-$ENV

# Create empty secrets folder
vault write secret/service/$SERVICE/$ENV name=$SERVICE

