#!/bin/bash

echo "Creating PoC model"

shopt -s expand_aliases
alias kcadm='/opt/keycloak/bin/kcadm.sh'
KC_REALM=PayPlus

kcadm config credentials --server http://keycloak:8081 --realm master --user $KEYCLOAK_USER --password $KEYCLOAK_PASSWORD
kcadm create realms -s realm=$KC_REALM -s enabled=true -s organizationsEnabled=true

kcadm update events/config -r $KC_REALM -s 'eventsListeners=["openfga-events-publisher","jboss-logging"]'

# Users
kcadm create users -r $KC_REALM -s username=paula.smith -s firstName=Paula -s lastName=Smith -s enabled=true -s email=paula.smith@orga.com
kcadm set-password -r $KC_REALM --username paula.smith --new-password demo1234!

# Organization
kcadm create organizations -r $KC_REALM -s alias=org-a -s name='org-a' -s domains[0]=orga.com
kcadm create organizations -r $KC_REALM -s alias=org-b -s name='org-b' -s domains[0]=orgb.com


# Role model
kcadm create roles -r $KC_REALM -s name=account-manager -s 'description=Account Manager'
kcadm create roles -r $KC_REALM -s name='view_transaction_any' -s 'description=View All Transactions'
kcadm add-roles -r $KC_REALM --rname account-manager --rolename 'view_transaction_any'

# User Role Assignments
kcadm add-roles -r $KC_REALM --uusername paula.smith --rolename account-manager


# Organization Assignment
## Magic Here !!
ORG_A_ID=$(kcadm get organizations -r PayPlus -q search='org-a' --fields 'id' --format csv --noquotes)
USER_PAULA=$(kcadm get users -r PayPlus -q exact=true -q username=paula.smith --fields 'id' --format csv --noquotes)
kcadm create organizations/$ORG_A_ID/members -r $KC_REALM -b $USER_PAULA


# Clients
kcadm create clients -r $KC_REALM -s clientId=portal -s publicClient=true -s 'redirectUris=["http://payplus.lab:4000/callback"]' -s 'webOrigins=["http://payplus.lab:4000"]' -s 'attributes={ "post.logout.redirect.uris": "http://payplus.lab:4000/home?action=logout"}' -o


