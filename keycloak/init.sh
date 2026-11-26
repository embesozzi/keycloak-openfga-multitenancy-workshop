#!/bin/bash
# Creates the PayPlus realm with organizations, the role model, the users and the portal client.
# The openfga-events-publisher extension publishes each change to OpenFGA:
# role assignments (role:...) and organization membership (organization:<alias>).
# Runs on every `docker compose up`: skipped when the realm already exists.
set -euo pipefail

kcadm() { /opt/keycloak/bin/kcadm.sh "$@"; }
REALM=PayPlus

kcadm config credentials --server "$KEYCLOAK_URL" --realm master --user "$KEYCLOAK_USER" --password "$KEYCLOAK_PASSWORD"

if kcadm get "realms/$REALM" >/dev/null 2>&1; then
  echo "Realm $REALM already imported, skipping"
  exit 0
fi

echo "Creating realm $REALM with organizations"
# sslRequired=NONE: the workshop runs on plain HTTP (workshop only)
kcadm create realms -s realm=$REALM -s enabled=true -s organizationsEnabled=true -s sslRequired=NONE

echo "Enabling the openfga-events-publisher event listener"
kcadm update events/config -r $REALM -s 'eventsListeners=["openfga-events-publisher","jboss-logging"]'

echo "Creating clients"
kcadm create clients -r $REALM -s clientId=portal -s publicClient=true \
  -s 'redirectUris=["http://payplus.lab:4000/callback"]' -s 'webOrigins=["http://payplus.lab:4000"]' \
  -s 'attributes={"post.logout.redirect.uris": "http://payplus.lab:4000/home?action=logout"}'
# Testing only (make test): password grant. Not recommended outside tests (RFC 9700).
kcadm create clients -r $REALM -s clientId=smoke-test -s publicClient=true \
  -s directAccessGrantsEnabled=true -s standardFlowEnabled=false

echo "Creating organizations"
kcadm create organizations -r $REALM -s alias=org-a -s name=org-a -s 'domains=[{"name":"orga.com"}]'
kcadm create organizations -r $REALM -s alias=org-b -s name=org-b -s 'domains=[{"name":"orgb.com"}]'

echo "Creating the role model"
kcadm create roles -r $REALM -s name=account-manager -s 'description=Account Manager'
kcadm create roles -r $REALM -s name=view_transaction_any -s 'description=View All Transactions'
kcadm add-roles -r $REALM --rname account-manager --rolename view_transaction_any

echo "Creating user paula.smith (password: demo1234!)"
kcadm create users -r $REALM -s username=paula.smith -s firstName=Paula -s lastName=Smith \
  -s email=paula.smith@orga.com -s emailVerified=true -s enabled=true
kcadm set-password -r $REALM --username paula.smith --new-password 'demo1234!'
kcadm add-roles -r $REALM --uusername paula.smith --rolename account-manager

echo "Adding paula.smith to org-a"
ORG_A_ID=$(kcadm get organizations -r $REALM -q search=org-a --fields id --format csv --noquotes)
PAULA_ID=$(kcadm get users -r $REALM -q exact=true -q username=paula.smith --fields id --format csv --noquotes)
kcadm create "organizations/$ORG_A_ID/members" -r $REALM -b "$PAULA_ID"

echo "Workshop configuration imported"
