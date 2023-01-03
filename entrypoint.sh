#!/bin/bash

export SCRIPT_DIR=/scripts

echo token: $VAULT_TOKEN

/bin/bash /scripts/create-taskrole.sh $1 $2 $3
/bin/bash /scripts/create-secret.sh $1 $2 $3 $4
