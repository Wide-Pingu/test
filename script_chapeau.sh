#!/bin/bash

./keycloak_export_helpers/export-git-config.sh
./exportGlobalRightsToNotion.sh
./exportSpecificRightsToNotion.sh
