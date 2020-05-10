#!/bin/bash
set -e
set -u
set -o xtrace

path="${0%/*}"
eksctl create cluster -f "$path"/values.yaml
