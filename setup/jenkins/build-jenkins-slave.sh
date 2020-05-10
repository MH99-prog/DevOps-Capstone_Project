#!/bin/bash
set -e
set -u
set -o xtrace

export REPO=$1
docker-compose build -f ../build-container/docker-compose.yml
docker-compose push -f ../build-container/docker-compose.yml

