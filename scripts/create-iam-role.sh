#!/bin/bash

source /opt/vault/bin/vault-env.sh

SERVICE=$1
ENV=$2
IAM_ROLE=$3

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

if [ -z "$IAM_ROLE" ]; then
	IAM_ROLE="arn:aws:iam::255382753382:role/credentials-$SERVICE-$ENV"
fi

vault token renew

# Create policy for the service to read its own secrets
cat << EOF > ./tmp-policy-service.hcl
path "secret/service/$SERVICE/$ENV" {
	capabilities = ["read"]
}
EOF
vault policy write service-$SERVICE-$ENV tmp-policy-service.hcl
rm tmp-policy-service.hcl

# Create an IAM role for the service
vault write auth/aws/role/service-$SERVICE-$ENV-iam region=eu-central-1 auth_type=iam bound_iam_principal_arn=$IAM_ROLE policies=service-base policies=service-$SERVICE-$ENV max_ttl=1h

# Create empty secrets folder if not yet existing
vault read secret/service/$SERVICE/$ENV &> /dev/null
if [ "$?" -ne "0" ]; then
	vault write secret/service/$SERVICE/$ENV name=$SERVICE
fi

