#!/bin/bash
set -e
set -u
set -o xtrace

kubectl -n kube-system create sa tiller

kubectl create clusterrolebinding tiller-cluster-rule \
    --clusterrole=cluster-admin \
    --serviceaccount=kube-system:tiller

helm init --service-account tiller --history-max 10

#TODO Secure helm installation!
# https://docs.helm.sh/using_helm/#securing-your-helm-installation

