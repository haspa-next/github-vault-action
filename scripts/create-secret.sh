#!/bin/bash

source /scripts/vault-env.sh

SERVICE=$1
ENV=$2
FILE=$3
METHOD=$4

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

if [ -z "$METHOD" ]; then
	METHOD="s3"
fi

if [ "$METHOD" -eq "iam" ]; then
	/opt/vault/bin/create-iam-role.sh $SERVICE $ENV
elif [ "$METHOD" -eq "s3" ]; then
	/opt/vault/bin/create-role.sh $SERVICE $ENV
	vault read auth/approle/role/service-$SERVICE-$ENV &> /dev/null
	if [ "$?" -ne "0" ]; then
		echo "Role for $SERVICE-$ENV does not exist"
		exit 1
	fi
else
	echo "Method '$METHOD' unknown"
	exit 1
fi

vault write -field=secret_id auth/approle/role/service-$SERVICE-$ENV/secret-id role_name=service-$SERVICE-$ENV > secret.tmp

if [ -z "$FILE" ]; then
	aws s3 cp secret.tmp s3://vault-credentials/$SERVICE-$ENV
	rm secret.tmp
else
	mv secret.tmp $FILE
fi
