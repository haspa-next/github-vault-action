#!/bin/bash

#
# This script will delete previously created vault roles (app role and iam role) and secrets for the given service and environment
# and thereby prevent future logins for those.
#
# Usage: ./delete-service.sh <SERVICE> <ENV> 
#
# Example: ./delete-service.sh content-xo stage
# 

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source $SCRIPT_DIR/vault-env.sh

SERVICE=$1
ENV=$2

if [ -z "$SERVICE" ]; then
	echo "Service name must be given, see script for usage instructions"
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

vault delete secret/service/$SERVICE/$ENV
vault delete auth/approle/role/service-$SERVICE-$ENV
vault delete auth/aws/role/service-$SERVICE-$ENV-iam 
vault policy delete service-$SERVICE-$ENV
