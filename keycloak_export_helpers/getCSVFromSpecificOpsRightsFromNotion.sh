#!/bin/bash

TRACKED_RIGHT="$1"
case "$TRACKED_RIGHT" in
       "demo")
            DATABASE_ID=$SPECIFIC_RIGHT_DEMO_DATABASE_ID
        ;;
        "formation")
            DATABASE_ID=$SPECIFIC_RIGHT_FORMATION_DATABASE_ID
        ;;
        "prod")
            DATABASE_ID=$SPECIFIC_RIGHT_PROD_DATABASE_ID
        ;;
        "staging-non-anonymized")
            DATABASE_ID=$SPECIFIC_RIGHT_STAGING_DATABASE_ID
        ;;
esac


REQUEST_RESULT=$(curl -X POST "https://api.notion.com/v1/databases/$DATABASE_ID/query" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H 'Notion-Version: 2022-06-28' \
  -H "Content-Type: application/json" \
   ) 


ALL_THE_EMAILS=$(echo "$REQUEST_RESULT" | jq   -r '.results[] | .properties[] | select(.type == "title") | .title[0].plain_text ') 

ALL_DATAS_FROM_NOTION_FOR_COMPARISON=""

JSON_FROM_KEYCLOAK=$($PATH_TO_GET_CSV_SPECIFIC_RIGHTS_KEYCLOAK $TRACKED_RIGHT)

LIST_OF_COLUMNS_FROM_KEYCLOAK=$(echo "$JSON_FROM_KEYCLOAK" | head -n 1 | cut -d ',' -f 2- | tr ',' $'\n' )

JSON_OF_COLUMNS_FROM_NOTION=$(curl "https://api.notion.com/v1/databases/$DATABASE_ID" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H 'Notion-Version: 2022-06-28' | jq -r '.properties[] | {id: .id, name: .name} ')

LIST_OF_COLUMNS_FROM_NOTION=$(echo "$JSON_OF_COLUMNS_FROM_NOTION" | jq -r '.name' | grep -v "Email" )

for EMAIL in $ALL_THE_EMAILS ; do
  LINE_TO_FILL="$EMAIL"
  for COLUMN in $LIST_OF_COLUMNS_FROM_KEYCLOAK ; do
    VALUE=$(echo $REQUEST_RESULT | jq -r '.results[] | select(.properties.Email.title[0].plain_text == "'"$EMAIL"'") .properties."'""$COLUMN'".rich_text[0].plain_text')
    LINE_TO_FILL+=",$VALUE"




    done
  LINE_TO_FILL+=$'\n'
  echo $LINE_TO_FILL

done
