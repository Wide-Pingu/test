#!/bin/bash

  TRACKED_RIGHT=$1
    UNPARSED_LIST_OF_CLIENT=''

    for OPS_RIGHTS_FILE in $(grep -Rl . rights/ops); do

        UNPARSED_LIST_OF_CLIENT+=$(cat $OPS_RIGHTS_FILE | grep "$TRACKED_RIGHT:.*:can-impersonate" | cut -d ':' -f 3 | grep -v "all-.*" )',' 
    done

    if [ "$TRACKED_RIGHT" = "demo" ]; then

        PARSED_LIST_OF_ALL_CLIENT=$'all-demos\n'$(echo "$UNPARSED_LIST_OF_CLIENT" | tr ',' $'\n' | sort -u | sed  '/^$/d')
    else
        PARSED_LIST_OF_ALL_CLIENT=$'all-clients\n'$(echo "$UNPARSED_LIST_OF_CLIENT" | tr ',' $'\n' | sort -u | sed  '/^$/d')

    fi

    #On remplit la première ligne du csv avec les infos de header, on place l'email au début 
    CSV_HEADERS='Email,'$(echo $PARSED_LIST_OF_ALL_CLIENT | tr ' ' ',')$'\n'
    echo $CSV_HEADERS 

    for OPS_RIGHTS_FILE in $(grep -rlnw 'rights/ops' -e "$TRACKED_RIGHT"":.*:can-impersonate"); do

        LINE_FOR_THIS_OPS=$(yq '.username' $OPS_RIGHTS_FILE)
        while IFS= read -r RIGHT; do
            if grep -q "$TRACKED_RIGHT"":all-clients:can-impersonate" $OPS_RIGHTS_FILE
                        
            then
                LINE_FOR_THIS_OPS+=',Oui'
            else
                if grep -q "$TRACKED_RIGHT"":$RIGHT"":can-impersonate" $OPS_RIGHTS_FILE 
                then
                    LINE_FOR_THIS_OPS+=',Oui'
                else
                    LINE_FOR_THIS_OPS+=',Non'
                    
                fi
            fi

        done <<< "$PARSED_LIST_OF_ALL_CLIENT"   
    echo $LINE_FOR_THIS_OPS
    done
