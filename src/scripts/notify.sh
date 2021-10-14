Notify() {
    # Check environment variables
    if [ -z "${R}" ] && [ -z "${N}" ]; then
        echo "Expect R (room id) or N (room name) to be provided"
        exit -1
    fi

    if [ -z "${M}" ]; then
        echo "Expect M (message) to be provided"
        exit -1
    fi

    if [ -z "${T}" ]; then
        echo "Expect T (Webex Token) to be provided" 
        exit -1
    fi

    echo "R: ${R}"
    echo "N: ${N}"
    echo "M: ${M}"
    echo "T: ${T}"

    # Determine R (Room ID) if it is not defined already
    if [ -z "${R}" ]; then
        RESPONSE=$(curl https://webexapis.com/v1/rooms -X GET -H "Authorization: Bearer $T" )
        echo "RESPONSE $RESPONSE"
        ROOMS=( $( echo $RESPONSE | jq -c '.items[] | select(.title==env.N)'))
        echo "ROOMS $ROOMS"
        if [ "${#ROOMS[@]}" != 1 ]; then
            echo "ERROR: Cannot determine Webex Room ID"
            echo "=== ${#ROOMS[@]} rooms found ==="
            echo $RESPONSE | jq '.items[] | select(.title==env.N)'
        else
            R=$( echo $ROOMS | jq '.id' )
            echo "Room id found: $R"
        fi
    fi

    # Send message to Webex
    echo "Sending message: ${M}"

    RESPONSE2=$( curl https://webexapis.com/v1/messages -X POST \
    -H "Authorization: Bearer $T" -H 'Content-Type: application/json' \
    -d "{\"roomId\": $R,\"markdown\": \"$M\"}" )
    echo $RESPONSE2
}

# Will not run if sourced for bats-core tests.
# View src/tests for more information.
ORB_TEST_ENV="bats-core"
if [ "${0#*$ORB_TEST_ENV}" == "$0" ]; then
    Notify
fi
