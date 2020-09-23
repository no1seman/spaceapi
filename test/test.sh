#!/bin/bash

TNT_SERVER_URI='http://localhost:8081'
USER='admin'
PASSWORD='admin'

SHOW_ANSWER=0

RED="\033[0;31m"
GREEN="\033[0;32m"
RESET="\033[0;0m"
CONTENT_TYPE_JSON='Content-Type: application/json'

function auth() {
    if [ $USER != '' ] && [ $PASSWORD != '' ]; then 
        AUTH_RESPONSE=$(curl -i -v -d 'username='$USER'&password='$PASSWORD -H 'Content-Type: application/x-www-form-urlencoded' $TNT_SERVER_URI/login 2>/dev/null | sed -n '/Set-cookie:/!d;s//&\n/;s/.*\n//;:a;/\;/bb;$!{n;ba};:b;s//\n&/;P;D' )
        AUTH_COOKIE='Cookie: '$AUTH_RESPONSE
    fi
}

function test() {
    HTTP_RESPONSE=$(curl --silent --write-out "HTTPSTATUS:%{http_code}" -X $1 -H '$AUTH_COOKIE' -H '$CONTENT_TYPE_JSON' -d "$3" $2)
    HTTP_BODY=$(echo $HTTP_RESPONSE | sed -E 's/HTTPSTATUS\:[0-9]{3}$//')
    HTTP_STATUS=$(echo $HTTP_RESPONSE | tr -d '\n' | sed -E 's/.*HTTPSTATUS:([0-9]{3})$/\1/')

    if [ $HTTP_STATUS == $4 ]; then
        echo -e $5" - "$GREEN"Success"$RESET
    else
        
        echo -e $5" - "$RED"Fail"$RESET
    fi
}

function get_space_id_by_name() {
    HTTP_RESPONSE=$(curl --silent --write-out "HTTPSTATUS:%{http_code}" -X GET -H '$AUTH_COOKIE' $TNT_SERVER_URI"/space?name=$1")
    HTTP_BODY=$(echo $HTTP_RESPONSE | sed -E 's/HTTPSTATUS\:[0-9]{3}$//')
    HTTP_STATUS=$(echo $HTTP_RESPONSE | tr -d '\n' | sed -E 's/.*HTTPSTATUS:([0-9]{3})$/\1/')
    SPACE_ID=$(echo $HTTP_BODY | grep -oP 'id":\s*\K\d+' | head -1)
}

new_space=$(cat <<-END
{
    "format": [
        {
            "name": "f1",
            "type": "unsigned"
        },
        {
            "name": "f2",
            "type": "string"
        },
        {
            "name": "f3",
            "type": "string"
        }
    ],
    "engine": "memtx",
    "ck_constraint": [
        {
            "space_id": 512,
            "is_enabled": true,
            "name": "c1",
            "expr": "\"f2\" > 'A'"
        },
        {
            "space_id": 512,
            "is_enabled": true,
            "name": "c2",
            "expr": "\"f2\"=UPPER(\"f3\") AND NOT \"f2\" LIKE '__'"
        }
    ],
    "temporary": false,
    "index": [
        {
            "unique": true,
            "parts": [
                {
                    "type": "unsigned",
                    "is_nullable": false,
                    "fieldno": 1
                }
            ],
            "id": 0,
            "type": "TREE",
            "name": "i"
        }
    ],
    "is_local": false,
    "name": "t"
}
END
)

auth

# Test creating space with corrupted POST data. Must return an error
test "POST" $TNT_SERVER_URI"/space" "$new_space}" "400" "Try to create new space with corrupted request data"
if (( SHOW_ANSWER == 1)); then 
    echo $HTTP_BODY 
fi

# Test creating space with name "t"
test "POST" $TNT_SERVER_URI"/space" "$new_space" "200" 'Create space with name "t"'
if (( SHOW_ANSWER == 1)); then 
    echo $HTTP_BODY 
fi
get_space_id_by_name "t"

# Test deleting space by id
test "DELETE" $TNT_SERVER_URI"/space?id=$SPACE_ID" "" "200" 'Delete space "t" by id'
if (( SHOW_ANSWER == 1)); then 
    echo $HTTP_BODY 
fi

# Test deleting unexistant space by id. Must return an error
test "DELETE" $TNT_SERVER_URI"/space?id=$SPACE_ID" "" "404" "Delete unexistant space by id"
if (( SHOW_ANSWER == 1)); then 
    echo $HTTP_BODY 
fi

# Test creating space with name "t" once more
test "POST" $TNT_SERVER_URI"/space" "$new_space" "200" 'Create space with name "t"'
if (( SHOW_ANSWER == 1)); then 
    echo $HTTP_BODY 
fi

# Test deleting space "t" by name
test "DELETE" $TNT_SERVER_URI"/space?name=t" "" "200" 'Delete space "t" by name'
if (( SHOW_ANSWER == 1)); then 
    echo $HTTP_BODY 
fi

# Test deleting unexistant space by name. Must return an error
test "DELETE" $TNT_SERVER_URI"/space?name=tdgdf" "" "404" "Delete unexistant space by name"
if (( SHOW_ANSWER == 1)); then 
    echo $HTTP_BODY 
fi

# Test creating space with name "t" once again
test "POST" $TNT_SERVER_URI"/space" "$new_space" "200" "Create space with name t"
if (( SHOW_ANSWER == 1)); then 
    echo $HTTP_BODY 
fi

# Test getting all spaces
test "GET" $TNT_SERVER_URI"/space" "" 200 "Get all spaces"
if (( SHOW_ANSWER == 1)); then 
    echo $HTTP_BODY 
fi

# Test getting space "t" by name 
test "GET" $TNT_SERVER_URI"/space?name=t" "" 200 "Get space by name"
if (( SHOW_ANSWER == 1)); then 
    echo $HTTP_BODY 
fi

# Test getting unexistant space by name 
test "GET" $TNT_SERVER_URI"/space?name=514" "" 404 "Try to get space with unexistant name"
if (( SHOW_ANSWER == 1)); then 
    echo $HTTP_BODY 
fi

# Test getting space with empty name 
test "GET" $TNT_SERVER_URI"/space?name=" "" 400 "Try to get space with empty name"
if (( SHOW_ANSWER == 1)); then 
    echo $HTTP_BODY 
fi

get_space_id_by_name "t"

# Test getting space by id 
test "GET" $TNT_SERVER_URI"/space?id=$SPACE_ID" "" 200 "Get space by id"
if (( SHOW_ANSWER == 1)); then 
    echo $HTTP_BODY 
fi

# Test getting unexistant space by id 
test "GET" $TNT_SERVER_URI"/space?id=1024" "" 404 "Try to get space with unexistant id"
if (( SHOW_ANSWER == 1)); then 
    echo $HTTP_BODY 
fi

# Test getting space by empty id 
test "GET" $TNT_SERVER_URI"/space?id=" "" 400 "Try to get space with empty id"
if (( SHOW_ANSWER == 1)); then 
    echo $HTTP_BODY 
fi

# Test getting space both by name and id 
test "GET" $TNT_SERVER_URI"/space?name=t&id=1024" "" 400 "Try to get space both by name and id"
if (( SHOW_ANSWER == 1)); then 
    echo $HTTP_BODY 
fi

# Cleanup test data by deleting space "t" by name
test "DELETE" $TNT_SERVER_URI"/space?name=t" "" "200" 'Delete space "t" by name'
if (( SHOW_ANSWER == 1)); then 
    echo $HTTP_BODY 
fi
