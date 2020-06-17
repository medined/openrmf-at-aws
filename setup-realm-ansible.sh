#!/bin/bash

LOG_FILE=$(basename $0).log
exec > >(tee ${LOG_FILE}) 2>&1

RMF_ADMIN_USER=${RMF_ADMIN_USER:-rmf-admin}

if [ -z $RMF_ADMIN_PASSWORD ]; then
  echo "Please set the RMF_ADMIN_PASSWORD env variable."
  exit
fi

#
# Docker is setup so that users do not need to sudo to use it.
#

#
# NOTE: It is expected that only one keyclock container is running.
# NOTE: The 'jq' utility is needed.
#

##BEGIN Locate Keycloak Container ID
#
# Using the container name is not helpful when searching because the
# first part of the name is based on the starting folder. For 
# example, "keycloak_keycloak_1" starts in /data/keycloak.
# 
echo
echo "Discovering local Keycloak Docker Container..."
keycontainer="$(docker ps | grep "jboss/keycloak:" | awk '{ print $1 }')"
echo "keycontainer: $keycontainer"
##END Locate Keycloak Container ID

echo
echo "Discovering local postgres Docker Container..."
dbcontainer="$(docker ps | grep "postgres:" | awk '{ print $1 }')"
echo "dbcontainer: $dbcontainer"
##END Locate Keycloak Container ID


KEYCLOAK_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $keycontainer)

##BEGIN Authenticate to Keycloak server
echo
echo "Authenticating to Keycloak Master Realm..."
docker exec $keycontainer /opt/jboss/keycloak/bin/kcadm.sh config credentials --server http://$KEYCLOAK_IP:8080/auth --realm master --user admin --password admin
##END Authenticate to Keycloak server

##BEGIN Create Realm
echo
echo "Creating the Realm..."
docker exec -i $keycontainer /opt/jboss/keycloak/bin/kcadm.sh create realms -s realm=openrmf -s enabled=true
##END Create Realm

##BEGIN Create Password Policy
echo
echo "Creating the Password Policy (12 digits, 2 upper, 2 lower, 2 number, 2 special character)..."
docker exec $keycontainer /opt/jboss/keycloak/bin/kcadm.sh update realms/openrmf -s 'passwordPolicy="hashIterations and specialChars and upperCase and digits and notUsername and length"'
##END Create Password Policy

##BEGIN Create Roles
echo
echo "Creating the 5 OpenRMF Roles..."
docker exec $keycontainer /opt/jboss/keycloak/bin/kcadm.sh create roles -r openrmf -s name=Administrator -s 'description=Admin role for openrmf'
docker exec $keycontainer /opt/jboss/keycloak/bin/kcadm.sh create roles -r openrmf -s name=Assessor -s 'description=Assessor Role for openrmf'
docker exec $keycontainer /opt/jboss/keycloak/bin/kcadm.sh create roles -r openrmf -s name=Download -s 'description=Download Role to pull down XLSX and CKL files in openrmf'
docker exec $keycontainer /opt/jboss/keycloak/bin/kcadm.sh create roles -r openrmf -s name=Editor -s 'description=Editor role for openrmf'
docker exec $keycontainer /opt/jboss/keycloak/bin/kcadm.sh create roles -r openrmf -s name=Reader -s 'description=Read-Only role for openrmf'
##END Create Roles

##BEGIN Create Client
echo
RESPONSE=$(docker exec -i $keycontainer /opt/jboss/keycloak/bin/kcadm.sh get clients -r openrmf -q clientId=openrmf 2>/dev/null)
cid=$(echo $RESPONSE | /usr/local/bin/jq --raw-output '.[0].id')
if [ -z $cid ] || [ $cid == "null" ]; then
  echo "Creating client"
  cid=$(docker exec -i $keycontainer /opt/jboss/keycloak/bin/kcadm.sh create clients -r openrmf -s enabled=true -s clientId=openrmf -s publicClient=true -s 'description=openrmf login for Web and APIs' -s 'redirectUris=["http://'$KEYCLOAK_IP':8080/*"]' -s 'webOrigins=["*"]' -i)
else
  echo "Client exists"
fi
echo "Client ID: $cid"
##END Create Client

##BEGIN Create Protocol Mapper
echo
echo "Creating the Client Protocol Mapper..."
docker exec -i $keycontainer /opt/jboss/keycloak/bin/kcadm.sh create \
  clients/$cid/protocol-mappers/models \
    -r openrmf \
    -s name=roles \
    -s protocol=openid-connect \
    -s protocolMapper=oidc-usermodel-realm-role-mapper \
    -s 'config."id.token.claim"=true' \
    -s 'config."claim.name"=roles' \
    -s 'config."jsonType.label"=String' \
    -s 'config."multivalued"=true' \
    -s 'config."userinfo.token.claim"=true' \
    -s 'config."access.token.claim"=true'
##END Create Protocol Mapper

##BEGIN Create first admin
echo
echo "Creating the first OpenRMF Administrator account..."
docker exec -i $keycontainer /opt/jboss/keycloak/bin/kcadm.sh create users -r openrmf -s username=$RMF_ADMIN_USER -s enabled=true -s 'requiredActions=["UPDATE_PASSWORD"]'
docker exec -i $keycontainer /opt/jboss/keycloak/bin/kcadm.sh add-roles --uusername $RMF_ADMIN_USER --rolename Administrator -r openrmf
docker exec -i $keycontainer /opt/jboss/keycloak/bin/kcadm.sh add-roles --uusername $RMF_ADMIN_USER --rolename Assessor -r openrmf
docker exec -i $keycontainer /opt/jboss/keycloak/bin/kcadm.sh add-roles --uusername $RMF_ADMIN_USER --rolename Download -r openrmf
docker exec -i $keycontainer /opt/jboss/keycloak/bin/kcadm.sh add-roles --uusername $RMF_ADMIN_USER --rolename Editor -r openrmf
docker exec -i $keycontainer /opt/jboss/keycloak/bin/kcadm.sh add-roles --uusername $RMF_ADMIN_USER --rolename Reader -r openrmf
##END Create first openrmf admin

##BEGIN Password Policy of 2/2/2/2 12 characters and not the same as the username
docker exec -i $keycontainer /opt/jboss/keycloak/bin/kcadm.sh update realms/openrmf -s 'passwordPolicy="hashIterations(27500) and specialChars(2) and upperCase(2) and digits(2) and notUsername(undefined) and length(12)"'
##END Password Policy

##BEGIN Add Reader Role to Default Realm Roles
echo
echo "Adding Reader Role to Default Realm Roles..."
docker exec -i $keycontainer /opt/jboss/keycloak/bin/kcadm.sh update realms/openrmf -f - <<EOF
{"defaultRoles" :["offline_access", "uma_authorization", "Reader"]}
EOF
##END Add Reader Role to Default Realm Roles

echo
echo "Turn of UPDATE_PASSWORD for RMF admin user."
RESPONSE=$(docker exec -i $keycontainer /opt/jboss/keycloak/bin/kcadm.sh get users --target-realm openrmf -q username=$RMF_ADMIN_USER 2>/dev/null)
RMF_ADMIN_USER_ID=$(echo $RESPONSE | /usr/local/bin/jq --raw-output '.[0].id')

docker exec -i $keycontainer  \
  /opt/jboss/keycloak/bin/kcadm.sh update \
    users/$RMF_ADMIN_USER_ID \
    --target-realm openrmf \
    --set 'requiredActions=[]'

echo
echo "Set RMF admin user password."
docker exec -i $keycontainer  \
  /opt/jboss/keycloak/bin/kcadm.sh set-password \
    --target-realm openrmf \
    --username $RMF_ADMIN_USER \
    --new-password "$RMF_ADMIN_PASSWORD"

#
# This script does not support http. So we need to tell that
# to keycloak.
# 
echo
echo "Unset https requirement."
docker exec $dbcontainer \
  psql \
    --host localhost \
    --dbname=keycloak \
    --username keycloak \
    --command="update REALM set ssl_required='NONE' where id = 'master';"

echo
echo "Complete."
