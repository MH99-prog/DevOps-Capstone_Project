#!/bin/bash

set -e
set -u
set -o xtrace

GH_USER=$1
GH_PASS=$2
GH_TOKEN=$3
DEPLOYMENT_REPO=$4
BRANCH=$5
CLUSTER_NAME=$6
DH_USER=$7
DH_PASS=$8
AWS_KEY_ID=$9
AWS_KEY=$10

echo "Waiting for tiller pod to be ready..."
kubectl wait --for condition=ready pod -l name=tiller --timeout=120s -n kube-system

helm repo add fluxcd https://charts.fluxcd.io

kubectl apply -f https://raw.githubusercontent.com/fluxcd/flux/helm-0.10.1/deploy-helm/flux-helm-release-crd.yaml

helm upgrade -i ${CLUSTER_NAME}-flux \
     --set helmOperator.create=true \
     --set helmOperator.createCRD=false \
     --set git.url=git@github.com:$GH_USER/$DEPLOYMENT_REPO \
     --set git.branch=$BRANCH \
     --namespace flux fluxcd/flux

echo "Waiting for flux pod to be ready..."
kubectl wait --for condition=ready pod -l app=flux --timeout=120s -n flux

export FLUX_FORWARD_NAMESPACE=flux

curl --netrc-file <(cat <<<"machine api.github.com login $GH_USER password $GH_PASS") \
     -d '{"title": "Flux Identity for EKS cluster '"$CLUSTER_NAME"' '"$(uuidgen)"'","key": "'"$(fluxctl identity)"'", "read_only": false}' \
     -H "Content-Type: application/json" \
     -X POST https://api.github.com/repos/$GH_USER/$DEPLOYMENT_REPO/keys


echo "Waiting for flux sync to succeed..."
ATTEMPTS=0
until fluxctl sync || [ $ATTEMPTS -eq 120 ]; do
  ATTEMPTS=$((ATTEMPTS + 1))
  sleep 5
done

path="${0%/*}"
./$path/create-secrets.sh $GH_USER $GH_PASS $GH_TOKEN $DEPLOYMENT_REPO $DH_USER $DH_PASS $AWS_KEY_ID $AWS_KEY $CLUSTER_NAME

echo "Syncing..."
fluxctl sync
