Notify() {
    # Check environment variables
    if [ -z "${R}" ] && [ -z "${N}" ]; then
        echo "Expect R (room id) or N (room name) to be provided"
        exit 1
    fi

    if [ -z "${M}" ]; then
        echo "Expect M (message) to be provided"
        exit 1
    fi

    if [ -z "${T}" ]; then
        echo "Expect T (Webex Token) to be provided" 
        exit 1
    fi

    # Determine R (Room ID) if it is not defined already
    if [ -z "${R}" ]; then
        RESPONSE=$(curl -s https://webexapis.com/v1/rooms -X GET -H "Authorization: Bearer $T" )
        HAS_ERROR=$( echo "$RESPONSE" | jq '.errors' )
        if [ "$HAS_ERROR" != "null" ]; then
            echo "ERROR $HAS_ERROR"
            exit 1;
        fi
        
        read -ra ROOMS <<< "$( echo "$RESPONSE" | jq -c '.items[] | select(.title==env.N)' )"

        if [ "${#ROOMS[@]}" != 1 ]; then
            echo "ERROR: Cannot determine Webex Room ID"
            echo "=== ${#ROOMS[@]} rooms found ==="
            echo "$RESPONSE" | jq '.items[] | select(.title==env.N)'
            exit 1;
        else
            R=$( echo "${ROOMS[0]}" | jq '.id' )
            echo "Room ID found: $R"
        fi
    fi

    # Send message to Webex
    RESPONSE2=$( curl -s https://webexapis.com/v1/messages -X POST \
        -H "Authorization: Bearer $T" -H 'Content-Type: application/json' \
        -d "{\"roomId\": $R,\"markdown\": \"$M\"}" )
    HAS_ERROR=$( echo "$RESPONSE2" | jq '.errors' )
    if [ "$HAS_ERROR" != "null" ]; then
        echo "ERROR $HAS_ERROR"
        exit 1;
    fi
    echo "Message sent: ${M}"
}

# Will not run if sourced for bats-core tests.
# View src/tests for more information.
ORB_TEST_ENV="bats-core"
if [ "${0#*$ORB_TEST_ENV}" == "$0" ]; then
    Notify
fi
