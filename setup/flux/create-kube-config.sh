#!/bin/bash
set -e
set -u
set -o xtrace
# Only here for historical reasons
# This is not used anymore. Was created before I understood RBAC.
CLUSTER_NAME=$1

aws eks describe-cluster --name $CLUSTER_NAME | jq "$(tr -d '\n' < "${0%/*}"/kube-template.json | tr -d '\t' )" > kube-config.json
yq r kube-config.json > config
rm kube-config.json