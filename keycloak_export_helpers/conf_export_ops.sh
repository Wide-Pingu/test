#!/bin/bash

#This script must be launched with source so that the env var can persist after its end.

#Common stuff
export VAULT_ADDR=https://vault.padoa.fr
export NOTION_KEY_VAULT_ADDRESS=secret/common/notion/integrationKeys
vault login -method=oidc -no-print 1>/dev/null 2>&1

export NOTION_KEY=$(vault kv get -format=json $NOTION_KEY_VAULT_ADDRESS| jq -r .data.data.isoControlExport)

#For the global right export and its helpers
export GLOBAL_RIGHTS_DATABASE_ID="c8d87376e06b4d73ad30298b3f63beeb"

export PATH_TO_GET_CSV_GLOBAL_RIGHTS_KEYCLOAK=~/tooling-ISO27001/keycloak_export_helpers/getCSVFromGlobalOpsRightsFromKeycloak.sh
export PATH_TO_GET_CSV_GLOBAL_RIGHTS_NOTION=~/tooling-ISO27001/keycloak_export_helpers/getCSVFromGlobalOpsRightsFromNotion.sh

#For the specific right export and its helpers

export SPECIFIC_RIGHT_DEMO_DATABASE_ID="1ce6922db1d04b0cb01c0e6d69ee18e3"
export SPECIFIC_RIGHT_FORMATION_DATABASE_ID="2a8cea723c2b42ed98c49d7c7cabde5d"
export SPECIFIC_RIGHT_PROD_DATABASE_ID="d2556f97e2aa498d815fa863c83b3a19"
export SPECIFIC_RIGHT_STAGING_DATABASE_ID="56132c8af42940fc8b78575eae728c94"

export PATH_TO_GET_CSV_SPECIFIC_RIGHTS_KEYCLOAK=~/tooling-ISO27001/keycloak_export_helpers/getCSVFromSpecificOpsRightsFromKeycloak.sh
export PATH_TO_GET_CSV_SPECIFIC_RIGHTS_NOTION=~/tooling-ISO27001/keycloak_export_helpers/getCSVFromSpecificOpsRightsFromNotion.sh
