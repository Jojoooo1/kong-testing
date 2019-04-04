#!/bin/bash
set -ev

# Kong call url from inside docker container
# Get Kong docker ip: ifconfig |grep -A2 docker
DOCKER_HOST="172.17.0.1"

BACKEND_HOST=$DOCKER_HOST
BACKEND_URL=http://${BACKEND_HOST}:3000/api/

# Load Balancer: Ring-balancer: Routing is done through **HOST** name
# UPSTREAM Object
http post http://localhost:8001/upstreams \
  name=api.v2.backend

sleep 2

# TARGETS Object to the upstream
http post http://localhost:8001/upstreams/api.v2.backend/targets \
  target=${BACKEND_HOST}:3000
# weight=100

# SERVICE Object
http post http://localhost:8001/services/ \
  name=api.v2.backend.service \
  host=api.v2.backend

sleep 2

# ROUTE Object
http post localhost:8001/services/api.v2.backend.service/routes \
  paths:='["/logistics/backend/v2/", "/backend/v2/"]' \
  hosts:='["api.v2.backend"]'

# check healty backend
http localhost:8000/backend/v2/api/health-check Host:api.v2.backend

# Canary release
# # first target at 1000
# curl -X POST http://kong:8001/upstreams/address.v2.service/targets \
#     --data "target=192.168.34.17:80"
#     --data "weight=1000"

# # second target at 0
# curl -X POST http://kong:8001/upstreams/address.v2.service/targets \
#     --data "target=192.168.34.18:80"
#     --data "weight=0"
