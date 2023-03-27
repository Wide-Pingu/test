#!/bin/bash

CONTENT_TO_WRITE_TO_CSV="Email,staging-anonymized:can-impersonate,Staging,Prod,Formation,Demo"$'\n'

for FILE in $(grep -Rl . rights/ops); do
    CONTENT_TO_WRITE_TO_CSV+=$(cat  $FILE | yq '.username')
    #By default this adds a yes because the first right is staging-anonymized:can-impersonate that every ops has
    CONTENT_TO_WRITE_TO_CSV+=',Oui'

    #Control of staging-non-anonymized::can-impersonate
    if grep -q "staging-non-anonymized:.*:can-impersonate" $FILE ; then
        if grep -q "staging-non-anonymized:all-clients:can-impersonate" $FILE ; then
            CONTENT_TO_WRITE_TO_CSV+=',All'
        else 
            CONTENT_TO_WRITE_TO_CSV+=',Some'
        fi
    else
        CONTENT_TO_WRITE_TO_CSV+=',None'
    fi

    #Control of prod:{client-name}:can-impersonate
    if grep -q "prod:.*:can-impersonate" $FILE ; then
        if grep -q "prod:all-clients:can-impersonate" $FILE ; then
            CONTENT_TO_WRITE_TO_CSV+=',All'
        else 
            CONTENT_TO_WRITE_TO_CSV+=',Some'
        fi
    else
        CONTENT_TO_WRITE_TO_CSV+=',None'
    fi

    #Control of formation:{client-name}:can-impersonate
    if grep -q "formation:.*:can-impersonate" $FILE ; then
        if grep -q "formation:all-clients:can-impersonate" $FILE ; then
            CONTENT_TO_WRITE_TO_CSV+=',All'
        else 
            CONTENT_TO_WRITE_TO_CSV+=',Some'
        fi
    else
        CONTENT_TO_WRITE_TO_CSV+=',None'
    fi

    #Control of demo:{stack-name}:can-impersonate
    if grep -q "demo:.*:can-impersonate" $FILE ; then
        if grep -q "demo:all-demos:can-impersonate" $FILE ; then
            CONTENT_TO_WRITE_TO_CSV+=',All'
        else 
            CONTENT_TO_WRITE_TO_CSV+=',Some'
        fi
    else
        CONTENT_TO_WRITE_TO_CSV+=',None'
    fi

    CONTENT_TO_WRITE_TO_CSV+=$'\n'
done
echo "$CONTENT_TO_WRITE_TO_CSV" 
