#!/bin/bash

#
# This script creates an IAM role for the given service and environment that allows service who run with the associated AWS IAM role to 
# login into this vault role and generate a token to access the services stored secrets
#
# The default IAM role will be arn:aws:iam::255382753382:role/credentials-$SERVICE-$ENV
#
# Usage: ./create-iam-role.sh <SERVICE> <ENV> [ <IAM_ROLE> ]
#   
# Example: ./create-iam-role.sh content-xo stage
# 

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source $SCRIPT_DIR/vault-env.sh

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

# Create an IAM role for the service
vault write auth/aws/role/service-$SERVICE-$ENV-iam region=eu-central-1 auth_type=iam bound_iam_principal_arn=$IAM_ROLE policies=service-base policies=service-$SERVICE-$ENV max_ttl=1h
