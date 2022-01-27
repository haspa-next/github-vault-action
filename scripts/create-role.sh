#!/bin/bash

#
# This script creates an approle for the given service and environment that allows someone with the associated secret_id to login 
# and generate a token to access the services stored secrets
#
# A secret_id will be automatically generated during the process and uploaded to the S3 path /vault-credentials/$SERVICE-$ENV 
# 
# Usage: ./create-role.sh <SERVICE> <ENV> 
#
# Example: ./create-role.sh content-xo stage
# 

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source $SCRIPT_DIR/vault-env.sh

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

# Create approle if not yet existing
NOT_FOUND_MSG="No value found"
ROLE=`vault read auth/approle/role/service-$SERVICE-$ENV 2>&1 1>/dev/null`

if [[ $ROLE =~ ^$NOT_FOUND_MSG* ]]; then
	echo "Role does not yet exist, new role will be created"

	# Create an app role for the service
	vault write auth/approle/role/service-$SERVICE-$ENV role_name=$SERVICE-$ENV policies=service-base policies=service-$SERVICE-$ENV secret_id_num_uses=0 secret_id_ttl=0 period=2764800 token_ttl=31536000 token_max_ttl=0
	vault write auth/approle/role/service-$SERVICE-$ENV/role-id role_id=service-$SERVICE-$ENV

    # Write secret-id that allows access to this app role into S3
    vault write -field=secret_id auth/approle/role/service-$SERVICE-$ENV/secret-id role_name=service-$SERVICE-$ENV > secret.tmp
    aws s3 cp secret.tmp s3://vault-credentials/$SERVICE-$ENV
    rm secret.tmp
else
	echo "Role for $SERVICE-$ENV already exists"
fi
