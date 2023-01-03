#!/bin/bash

export SCRIPT_DIR=/scripts

sh /scripts/create-taskrole.sh $1 $2 $3
sh /scripts/create-secret.sh $1 $2 $3 $4
