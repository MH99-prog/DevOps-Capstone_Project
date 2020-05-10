#!/bin/bash
kubectl port-forward -n capstone-monitor "$(kubectl get -n capstone-monitor pod --selector=weave-scope-component=app -o jsonpath='{.items..metadata.name}')" 4040