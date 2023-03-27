#!/bin/bash


cd keycloak-rights

#We get the basics constants that we need

DATABASE_ID=$GLOBAL_RIGHTS_DATABASE_ID
export PATH_TO_GET_CSV_GLOBAL_RIGHTS_KEYCLOAK=/keycloak_export_helpers/getCSVFromGlobalOpsRightsFromKeycloak.sh
export PATH_TO_GET_CSV_GLOBAL_RIGHTS_NOTION=/keycloak_export_helpers/getCSVFromGlobalOpsRightsFromNotion.sh


if [[ -z "$NOTION_KEY" ]] ; then
  export VAULT_ADDR=https://vault.padoa.fr
  export NOTION_KEY_VAULT_ADDRESS=secret/common/notion/integrationKeys
  vault login -method=oidc -no-print 1>/dev/null 2>&1
  export NOTION_KEY=$(vault kv get -format=json $NOTION_KEY_VAULT_ADDRESS| jq -r .data.data.isoControlExport)

  if [[ -z "$NOTION_KEY" ]] ; then
    echo "Please make sure that there is a key at the address : $NOTION_KEY_VAULT_ADDRESS in the vault"
    exit 1
  fi
fi

#This makes a query of the whole notion database, from which we can parse most of our data so we don't have to call the api again.
WHOLE_BASE=$(curl -X POST "https://api.notion.com/v1/databases/$DATABASE_ID/query" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H 'Notion-Version: 2022-06-28' \
  -H "Content-Type: application/json" \
   ) 

#This creates a json with 1 item for every page of the table containing the email adress of the page and its ID, this is used when we need to delete a page   
JSON_OF_EMAIL_AND_PAGE_ID=$(echo "$WHOLE_BASE" | jq '.results[] | {email: .properties.Email.title[0].plain_text, id: .id} ')


#This is roughly the same, it is used to compare with the list from keycloak to find any difference
JSON_OF_COLUMNS_FROM_NOTION=$(curl "https://api.notion.com/v1/databases/$DATABASE_ID" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H 'Notion-Version: 2022-06-28' | jq -r '.properties[] | {id: .id, name: .name} ')


LIST_OF_COLUMNS_FROM_NOTION=$(echo "$JSON_OF_COLUMNS_FROM_NOTION" | jq -r '.name' | grep -v "Email" | sort )

LIST_OF_COLUMNS_FROM_KEYCLOAK=$($PATH_TO_GET_CSV_GLOBAL_RIGHTS_KEYCLOAK | head -n 1 | cut -d ',' -f 2- | tr ',' $'\n' | sort)

#We delete and add columns based on the difference between the list of column from keycloak and notion
LIST_OF_COLUMNS_TO_DELETE=$(diff  --suppress-common-line  <(echo "$LIST_OF_COLUMNS_FROM_KEYCLOAK" ) <(echo "$LIST_OF_COLUMNS_FROM_NOTION" ) | grep ">" | cut -f 2 -d ">")

for COLUMN_TO_DELETE in $LIST_OF_COLUMNS_TO_DELETE ; do
  echo "Deleting column $COLUMN_TO_DELETE"
  if [[ $COLUMN_TO_DELETE != "title" ]] ; then
    REQUEST_RESULT=$(curl -X PATCH "https://api.notion.com/v1/databases/$DATABASE_ID" \
      -H 'Authorization: Bearer '"$NOTION_KEY"'' \
      -H "Content-Type: application/json" \
      -H "Notion-Version: 2022-06-28" \
      --data '{"properties": {
            "'"$COLUMN_TO_DELETE"'": null
    }}')
  fi
done

#We get the list of collums to add, then we add them
LIST_OF_COLUMNS_TO_ADD=$(diff  --suppress-common-line  <(echo "$LIST_OF_COLUMNS_FROM_KEYCLOAK" ) <(echo "$LIST_OF_COLUMNS_FROM_NOTION" ) | grep "<" | cut -f 2 -d "<")

for COLUMN_TO_ADD in $LIST_OF_COLUMNS_TO_ADD ; do
  echo "Adding column $COLUMN_TO_ADD"
  if [[ $COLUMN_TO_ADD != "Email" ]]; then
    REQUEST_RESULT=$(curl -X PATCH "https://api.notion.com/v1/databases/$DATABASE_ID" \
    -H 'Authorization: Bearer '"$NOTION_KEY"'' \
    -H "Content-Type: application/json" \
    -H "Notion-Version: 2022-06-28" \
    --data '{
        "properties": {
          "'"$COLUMN_TO_ADD"'": {
          "id": "'"$COLUMN_TO_ADD"'",
          "name": "'"$COLUMN_TO_ADD"'",
          "type": "rich_text",
          "rich_text": {}
          }
        }
    }'
    )


  fi
done

RESULT_OF_DIFF=$(diff --suppress-common-line  <($PATH_TO_GET_CSV_GLOBAL_RIGHTS_KEYCLOAK | tail -n+2 | sort) <($PATH_TO_GET_CSV_GLOBAL_RIGHTS_NOTION | sort ) )
LIST_OF_PAGE_TO_DELETE=$(echo "$RESULT_OF_DIFF" | grep -e "|" -e ">" | tr -d '| ' | tr -d '> ' | cut -f 1 -d ',')

LIST_OF_PAGE_TO_ADD=$(echo "$RESULT_OF_DIFF" | grep -e "|" -e "<" | tr -d '| ' | tr -d '< ' | tr ',' ' ')

#Same here, we delete any page that appear in the diff from notion, then create any page that appear in the diff from keycloak. 
#This means that if a line has a different value on notion that on keycloak, its going to be deleted and replaced
for EMAIL in $LIST_OF_PAGE_TO_DELETE ; do
  echo "Deleting $EMAIL"
  ID_OF_PAGE_TO_DELETE=$(echo "$JSON_OF_EMAIL_AND_PAGE_ID" | jq -r 'select(.email=="'"$EMAIL"'") | .id')
  REQUEST_RESULT=$(curl -X PATCH "https://api.notion.com/v1/pages/$ID_OF_PAGE_TO_DELETE" \
  -H 'Authorization: Bearer '"$NOTION_KEY"'' \
  -H "Content-Type: application/json" \
  -H "Notion-Version: 2022-06-28" \
  --data '{
  "archived": true
  }'
  )
done
#This check prevents the program from creating an empty page when there isn't any page to add
    if [[ -z "$LIST_OF_PAGE_TO_ADD" ]]; then
        exit 0

    fi
#Now we add the pages with the required informations

LIST_OF_COLUMNS_TO_FILL=$($PATH_TO_GET_CSV_GLOBAL_RIGHTS_KEYCLOAK  | tr ',' ' ' | head -n 1 | cut -f 2- -d ' ' )

while IFS= read -r line; do

  #First we store in "EMAIL" the email adress of the ops
  EMAIL=$(echo "$line" | cut -f 1 -d ' ')
  echo "Adding $EMAIL"
    JSONSTR='{
        "parent": { 
        "type": "database_id",
         "database_id": "'"$DATABASE_ID"'" 
        },
        "properties": {
        "Email": {
          "type": "title",
          "title": 
          [
            { 
            "type": "text",
            "text":
              {
               "content": "'"$EMAIL"'" 
              } 
            }
          ]
        }'
        
  #Then for each subsequent element of the list, we add the adequat piece to the json

  LIST_WITHOUT_THE_HEAD=$(echo "$line" | cut -f 2- -d ' ')
  COUNT=0
  for ELEMENT_OF_THE_LIST in $LIST_WITHOUT_THE_HEAD ; do
    COUNT=$((COUNT+1))
    COLUMN_TO_FILL=$(echo $LIST_OF_COLUMNS_TO_FILL | cut -f $COUNT -d ' ')

    case "$ELEMENT_OF_THE_LIST" in
      "Oui")
        JSONSTR+=', "'"$COLUMN_TO_FILL"'": 
        {
         "rich_text": [{ 
          "text": { "content":"'"$ELEMENT_OF_THE_LIST"'" },
              "annotations": {
              "bold": true,
              "italic": true,
              "strikethrough": false,
              "underline": false,
              "code": false,
              "color": "blue"
            }
        }]
      }'
      ;;
      "All")
        JSONSTR+=', "'"$COLUMN_TO_FILL"'": 
        {
         "rich_text": [{ 
          "text": { "content":"'"$ELEMENT_OF_THE_LIST"'" },
              "annotations": {
              "bold": true,
              "italic": true,
              "strikethrough": false,
              "underline": false,
              "code": false,
              "color": "green"
            }
        }]
      }'
     ;;
     "Some")
        JSONSTR+=', "'"$COLUMN_TO_FILL"'": 
        {
         "rich_text": [{ 
          "text": { "content":"'"$ELEMENT_OF_THE_LIST"'" },
              "annotations": {
              "bold": true,
              "italic": true,
              "strikethrough": false,
              "underline": false,
              "code": false,
              "color": "yellow"
            }
        }]
      }'
      ;;
      "None")
        JSONSTR+=', "'"$COLUMN_TO_FILL"'": 
        {
         "rich_text": [{ 
          "text": { "content":"'"$ELEMENT_OF_THE_LIST"'" },
              "annotations": {
              "bold": true,
              "italic": true,
              "strikethrough": false,
              "underline": false,
              "code": false,
              "color": "red"
            }
        }]
      }'
      ;;
    esac
  done

  JSONSTR+='
      }
    }'
    
  REQUEST_RESULT=$(curl -X POST 'https://api.notion.com/v1/pages' \
    -H "Authorization: Bearer $NOTION_KEY" \
    -H 'Notion-Version: 2022-06-28' \
    -H "Content-Type: application/json" \
    -d "$JSONSTR" \
       )
 
done <<< "$LIST_OF_PAGE_TO_ADD"



