#!/bin/bash

sh /scripts/create-taskrole.sh $1 $2
sh /scripts/create-secret.sh $1 $2 $3
