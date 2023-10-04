#!/bin/zsh
#
# Run this script to obtain the RTM REST API token that will be required to
# invoke its REST API methods. This script should only be used once, or whenever
# permission has been revoked for this App, in which case a new token will be
# necessary.
#
# Usage:
# 1. Apply for an API key from here https://www.rememberthemilk.com/services/api/.
# 2. Run this script by passing the shared secret and API key as follows:
#    . /path/to/auth.zsh <sharedSecret> <apiKey>
# 3. Follow the instructions provided by the output from the previous step.

rtmREST=https://api.rememberthemilk.com/services/rest/
rtmAuthURL=https://www.rememberthemilk.com/services/auth/

sharedSecret=$1
apiKey=$2
rtmFrob=""

function RTMSign {
    params=$1
    echo $(md5 -q -s $sharedSecret$params)
}

function RTMGetToken {
    apiSig=$(RTMSign "api_key"$apiKey"formatjsonfrob"$rtmFrob"methodrtm.auth.getToken")
    response=$(curl -s "$rtmREST?api_key=$apiKey&format=json&method=rtm.auth.getToken&frob=$rtmFrob&api_sig=$apiSig")
    if [[ -n $(echo $response|grep "\"stat\":") ]];then
        if [[ $(echo $response|jq ".rsp.stat") = "\"ok\"" ]];then
            echo $response # TODO: Remove this when no longer needed
            rtmToken=$(echo $response|jq ".rsp.auth.token"|sed 's/"//g')
            echo "Add these lines in your .zshrc:"
            echo "export VIMODORO_RTM_API_KEY=$apiKey"
            echo "export VIMODORO_RTM_SECRET=$sharedSecret"
            echo "export VIMODORO_RTM_TOKEN=$rtmToken"
        else
            # TODO: Do something meaningful
            echo $response
        fi
    else
        echo "Something went wrong. We got this response from RTM when calling its API."
        echo $response
    fi
}

function RTMAuthentication {
    apiSig=$(RTMSign "api_key"$apiKey"formatjsonmethodrtm.auth.getFrob")
    response=$(curl -s "$rtmREST?api_key=$apiKey&format=json&method=rtm.auth.getFrob&api_sig=$apiSig")

    if [[ -n $(echo $response|grep "\"stat\":") ]];then
        if [[ $(echo $response|jq ".rsp.stat") = "\"ok\"" ]];then
            rtmFrob=$(echo $response|jq ".rsp.frob"|sed 's/"//g')
            apiSig=$(RTMSign "api_key"$apiKey"frob"$rtmFrob"permsdelete")
            appAuthURL="$rtmAuthURL?api_key=$apiKey&perms=delete&frob=$rtmFrob&api_sig="$apiSig

            echo "This application needs to get permission from RTM to do its functions."

            if [[ $(uname) = "Darwin" ]];then
                open $appAuthURL
                echo "Log in into your RTM if prompted, then give authorization from the RTM page."
            else
                echo "Copy and paste below URL to your browser, log in into your RTM if prompted, then give authorization from the RTM page."
                echo
                echo $appAuthURL
            fi

            vared -p "Press ENTER once you have given the authorization to this App." -c t

            RTMGetToken
        else
            # TODO: Do something meaningful
            echo $response
        fi
    else
        echo "Something went wrong. We got this response from RTM when calling its API."
        echo $response
    fi
}

which jq > /dev/null
[[ $? -eq 0 ]];has_jq=true || has_jq=false

if [[ "$has_jq" == true ]];then
    RTMAuthentication
else
    echo "This script requires 'jq'. Please install it prior to proceeding."
fi
