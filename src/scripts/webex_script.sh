#!/bin/bash

display_help() {
    echo "Usage: ./notify.sh [opts]"
    echo "  -r              Room/Space ID"
    echo "  -n              Room/Space Name"
    echo "  -m              Message to send (Markdown)"
    echo "  -t              Circle CI BOT Token"
}

while getopts ":n:m:t:r:h" opt; do
  case $opt in
    r) R=${OPTARG};;
    n) N=${OPTARG};;
    m) M=${OPTARG};;
    t) T=${OPTARG};;
    h) display_help
        exit 0;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      display_help
      exit -1;;
  esac
done

# Check environment variables
if [ -z "${R}" ] && [ -z "${N}" ]; then
    echo "Expect R (room id) or N (room name) to be provided"
    display_help
    exit -1
fi

if [ -z "${M}" ]; then
    echo "Expect M (message) to be provided"
    display_help
    exit -1
fi

if [ -z "${M}" ] || [ -z "${T}" ]; then
    echo "Expect T (Webex Token) to be provided"
    display_help
    exit -1
fi

# Determine R (Room ID) if it is not defined already
if [ -z "${R}" ]; then
    RESPONSE=$(curl https://webexapis.com/v1/rooms -X GET -H "Authorization: Bearer $T" )
    ROOMS=( $( echo $RESPONSE | jq -c '.items[] | select(.title==env.N)'))

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
RESPONSE2=$(curl https://webexapis.com/v1/messages -X POST \
    -H "Authorization: Bearer $T" -H 'Content-Type: application/json' \
    -d "{\"roomId\": \"$R\",\"markdown\": \"$M\"}")
echo $RESPONSE2
