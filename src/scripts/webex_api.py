#!/usr/local/bin/python3

import argparse
import json
import os
import requests
from dotenv import load_dotenv

base_url = 'https://webexapis.com/v1/'
headers = {'Content-Type': 'application/json'}

def webex_post(endpoint, data={}):
    return requests.post(os.path.join(base_url, endpoint), data=json.dumps(data), headers=headers)

def webex_get(endpoint):
    return requests.get(os.path.join(base_url, endpoint), headers=headers)

def api_request(method, endpoint, data={}):
    try:
        if method == 'POST':
            response = webex_post(endpoint, data=data)
        elif method == 'GET':
            response = webex_get(endpoint)
        else:
            raise SystemExit('ERROR: Unknown HTTP method: %s' % method)
    except requests.exceptions.RequestException as e:
        print('ERROR: Failed to make a GET request to webex')
        raise SystemExit(e)
    
    if response.status_code != 200:
        raise SystemExit('ERROR: Status Code %i \n %s' % (response.status_code, response.text))
    else:
        print('Webex API Status Code:', response.status_code)
    return response

def arg_parser():
    parser = argparse.ArgumentParser('webex_api')
    parser.add_argument('-r', '--room_id', dest='ROOM_ID', help='Room/Space ID')
    parser.add_argument('-n', '--room_name', dest='ROOM_NAME', help='Room/Space Name' )
    parser.add_argument('-m', '--message', dest='MESSAGE', help='Message to send (Markdown)')
    parser.add_argument('-t', '--token', dest='TOKEN', help='Circle CI BOT Token')
    return parser.parse_args()

def main():
    load_dotenv()
    args = arg_parser()
    ROOM_ID = args.ROOM_ID or os.getenv('R')
    ROOM_NAME = args.ROOM_NAME or os.getenv('N')
    MESSAGE = args.MESSAGE or os.getenv('M')
    TOKEN = args.TOKEN or os.getenv('T')
    
    # Exit if TOKEN or ROOM_ID (or ROOM_NAME) or MESSAGE isn't provided
    if TOKEN == None:
        print('ERROR: Please provide the CircleCI TOKEN')
        return -1
    if ROOM_ID == None and ROOM_NAME == None:
        print('ERROR: Please provide ROOM_ID (or unique ROOM_NAME)')
        return -1
    if not MESSAGE:
        print('ERROR: lease provide a message')
        return -1

    # Add TOKEN
    token = {'Authorization' : f"Bearer {TOKEN}"}
    headers.update(token)

    # Get ROOM_ID - https://developer.webex.com/docs/api/v1/rooms/list-rooms
    if ROOM_ID == None:
        rooms_request = api_request('GET', endpoint='rooms')
        rooms = []
        if 'items' in rooms_request.json():
            rooms = rooms_request.json()['items']    
        dest_rooms = [room for room in rooms if ROOM_NAME in room['title']]

        if len(dest_rooms) < 1 or len(dest_rooms) > 1:
            print('ERROR: Cannot determine ROOM_ID')
            print('===', len(dest_rooms), 'rooms found:', '===\n')
            print(*dest_rooms, sep="\n\n")
            return -1
        else:
            ROOM_ID = dest_rooms[0]['id']
        
    # Send message to ROOM_ID - https://developer.webex.com/docs/api/v1/messages/create-a-message
    payload = {'roomId': ROOM_ID, 'markdown': MESSAGE}
    api_request('POST', endpoint='messages', data=payload)

if __name__ == "__main__":
    main()
