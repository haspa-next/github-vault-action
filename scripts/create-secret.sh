#!/bin/bash

#
# This script creates a vault secret container for the given service and environment if it not yet exist.
# It will also generate a vault policy that allows roles that login with this policy to access the generated secret container.
#
# As a convenience, if the method argument is specified, this script will also generate the matching approle or IAM role, depending
# on the method given.
#
# Usage: ./create-secret.sh <SERVICE> <ENV> [ <METHOD> [ <IAM_ROLE> ]]
#
# Supported methods are either "s3" or "iam".
#
# Example: ./create-secret.sh content-xo stage iam
#   

source $SCRIPT_DIR/vault-env.sh

SERVICE=$1
ENV=$2
METHOD=$3
IAM_ROLE=$4

if [ -z "$SERVICE" ]; then
	echo "Usage: create-secret.sh <rolename>"
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
	ENV=stage
fi


# Create policy for the service to read its own secrets

cat << EOF > ./tmp-policy-service.hcl
path "secret/service/$SERVICE/$ENV" {
	capabilities = ["read"]
}
EOF
vault policy write service-$SERVICE-$ENV tmp-policy-service.hcl
rm tmp-policy-service.hcl


# Create empty secrets folder if not yet existing

NOT_FOUND_MSG='^No value found*'
SECRET=`vault read secret/service/$SERVICE/$ENV 2>&1 1>/dev/null`

if [[ $SECRET =~ $NOT_FOUND_MSG ]]; then
	echo "Secret does not exist, new empty secret created"
	vault write secret/service/$SERVICE/$ENV name=$SERVICE
else
	echo "The secret for this service already exists"
fi


# Create role for the service to access its secrets if a method is given

if [ -z "$METHOD" ]; then
    exit 0
fi

if [[ "$METHOD" == "iam" ]]; then
	$SCRIPT_DIR/create-iam-role.sh $SERVICE $ENV $IAM_ROLE
elif [[ "$METHOD" == "s3" ]]; then
    $SCRIPT_DIR/create-role.sh $SERVICE $ENV
else
	echo "Method '$METHOD' unknown"
	exit 1
fi

