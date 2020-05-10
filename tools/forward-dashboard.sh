#!/bin/bash
echo "Token for login"
kubectl get secret default-token-5dhkd -n=kube-system -o json | jq -r '.data["token"]' | base64 -d
export POD_NAME=$(kubectl get pods -n capstone-monitor -l "app=kubernetes-dashboard,release=kubernetes-dashboard" -o jsonpath="{.items[0].metadata.name}")
kubectl -n capstone-monitor port-forward $POD_NAME 8443:8443

