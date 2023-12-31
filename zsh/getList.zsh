#!/bin/zsh
#
# Method:
# rtm.tasks.getList
#
# Description
# Retrieves a list of tasks.
#
# If list_id is not specified, all tasks are retrieved, unless filter is specified.
#
# If last_sync is provided, only tasks modified since last_sync will be
# returned, and each <list> element will have an attribute, current, equal to
# last_sync.
#
# Availability
# Available in versions 1 and 2.
#
# Authentication
# This method requires authentication with read permissions.
#
# Arguments
# api_key (Required) 1 2
# Your API application key. See here for more details.
#
# list_id 1 2
# The id of the list to perform an action on.
#
# filter 1 2
# If specified, only tasks matching the desired criteria are returned. See here for more details.
#
# last_sync 1 2
# An ISO 8601 formatted time value. If last_sync is provided, only tasks
# modified since last_sync will be returned, and each element will have an
# attribute, current, equal to last_sync.
#
# callback 1 2
# Optional callback to wrap JSON response in

rtmREST=https://api.rememberthemilk.com/services/rest/

apiKey=$VIMODORO_RTM_API_KEY
authToken=$VIMODORO_RTM_TOKEN
sharedSecret=$VIMODORO_RTM_SECRET

filter="dueBefore:tomorrow AND status:incomplete"

function RTMSign {
    params=$1
    echo $(md5 -q -s $sharedSecret$params)
}

function RTMGetList {
    apiSig=$(RTMSign "api_key"$apiKey"auth_token"$authToken"filter"$filter"formatjsonmethodrtm.tasks.getList")
    filter=$(echo $filter|sed 's/\ /%20/g')
    response=$(curl -s "$rtmREST?api_key=$apiKey&format=json&method=rtm.tasks.getList&filter=$filter&auth_token=$authToken&&api_sig=$apiSig")
    response=$(echo $response|awk '{ printf "%s", $0 } END { print "" }')
    if [[ -n $(echo $response|grep "\"stat\":") ]];then
        if [[ $(echo $response|jq ".rsp.stat") = "\"ok\"" ]];then
            echo $response # TODO: Remove this when no longer needed
            # rtmToken=$(echo $response|jq ".rsp.auth.token"|sed 's/"//g')
        else
            # TODO: Do something meaningful
            echo "Something went wrong. We got this response from RTM when calling its API."
            echo $response
        fi
    else
        echo "Something went wrong with the CURL command."
        echo $response
    fi
}

RTMGetList
