#!/bin/bash
set -ev

# Kong call url from inside docker container
# Get Kong docker ip: ifconfig |grep -A2 docker 
DOCKER_HOST="172.17.0.1" 

BACKEND_ADMIN_HOST=$DOCKER_HOST
BACKEND_ADMIN_URL=http://${BACKEND_ADMIN_HOST}:3000/admin/api/

HTTPS_CONNECTION=false # **ALERT** not forget to set secure cookie

# Admin
http post localhost:8001/services \
    name=logistics.v2.backend.admin \
    url=$BACKEND_ADMIN_URL

sleep 2

# Admin
http post localhost:8001/services/logistics.v2.backend.admin/routes \
    paths:='["/logistics/backend/v2/admin", "/backend/v2/admin"]' # preserve_host:='false' # strip_path:='true' by default remove "/logistics/backend/v2/api/ from request 

# Adds **BASIC-AUTH & ACL**
# Admin activate plugin basic-auth
http post http://localhost:8001/services/logistics.v2.backend.admin/plugins/ \
  name=basic-auth \
  config:='{"hide_credentials": true}' # default false
sleep 2
# Adds ACL plugin & Whitelist admin on admin backend
http post http://localhost:8001/services/logistics.v2.backend.admin/plugins \
  name=acl \
  config:='{"whitelist": ["admin"], "hide_groups_header": false}'

# Adds **Admin User**
ADMIN_USERNAME=jonathan
ADMIN_PASSWORD=jonathan

# Creates **CONSUMER (The Consumer object represents a consumer - or a user - of a Service)
# Set USERNAME
http post  http://localhost:8001/consumers/ \
  username=$ADMIN_USERNAME 
  # tags="admin_user"
sleep 1
# Set PASSWORD
http post http://localhost:8001/consumers/${ADMIN_USERNAME}/key-auth/ \
  key="${ADMIN_PASSWORD}"
  # custom_id=SOME_CUSTOM_ID" # Field for storing an existing unique ID for the consumer - useful for mapping Kong with users in your existing database
sleep 1
# set ACL admin
http post http://localhost:8001/consumers/${ADMIN_USERNAME}/acls \
    group=admin_user

# # Adds **COOKIE SESSION PLUGIN**
# # set session only cookies (non-persistent, and HttpOnly) so that the cookies are not readable from Javascript (not subjectible to XSS in that matter). 
# # It will also set Secure flag by default when the request was made via SSL/TLS connection
# # By default, Kong Session plugin favors security using a Secure, HTTPOnly, Samesite=Strict cookie. 
# # cookie_domain is automatically set using Nginx variable host, but can be overridden.
http post http://localhost:8001/services/logistics.v2.backend.admin/plugins \
    name=session \
    config:='{"storage": "kong", "cookie_secure": false}' # **ALERT** SET COOKIE SECURE


# TEST backend API
http localhost:8000/logistics/backend/v2/health-check