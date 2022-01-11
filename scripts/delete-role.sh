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

vault read auth/approle/role/service-$SERVICE-$ENV &> /dev/null
if [ "$?" -ne "0" ]; then
	echo "Role for $SERVICE does not exist"
	exit 1
fi

vault delete secret/service/$SERVICE/$ENV
vault delete auth/approle/role/service-$SERVICE-$ENV
vault policy delete service-$SERVICE-$ENV
