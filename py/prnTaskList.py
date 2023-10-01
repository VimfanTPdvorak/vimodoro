import vim
import datetime
import sys
import os
import json
import traceback
import hashlib
import requests

rtmREST = vim.eval("s:rtmREST")

apiKey = os.getenv("VIMODORO_RTM_API_KEY")
authToken = os.getenv("VIMODORO_RTM_TOKEN")
sharedSecret = os.getenv("VIMODORO_RTM_SECRET")

if len(sys.argv) > 1:
    rtmFilter = sys.argv[1]
else:
    rtmFilter = "dueBefore:tomorrow AND status:incomplete"

def RTM_Sign(params):
    return hashlib.md5((sharedSecret+params).encode()).hexdigest()

def RTM_GetListName(listID):
    apiSig = RTM_Sign("api_key"+apiKey+"auth_token"+authToken+"formatjsonmethodrtm.lists.getList")
    response = requests.get(f"{rtmREST}?api_key={apiKey}&format=json&method=rtm.lists.getList&auth_token={authToken}&api_sig={apiSig}")
    response = response.text
    lists = json.loads(response)
    if "stat" in response:
        if lists["rsp"]["stat"] == "ok":
            l = lists["rsp"]["lists"]["list"]
            for i in range(len(l)):
                if l[i]['id'] == listID:
                    return l[i]['name']
            return '' # Passed list ID not found.
        else:
            # TODO: Handle it gracefully.
            return 'Error'
    else:
        # TODO: Handle it gracefully.
        return 'Error'

def RTM_PrintTasksList(rtmFilter):
    vim.command("echo '::Getting Tasks...'")
    vim.command("redraw")
    apiSig = RTM_Sign("api_key"+apiKey+"auth_token"+authToken+"filter"+rtmFilter+"formatjsonmethodrtm.tasks.getList")
    rtmFilter = rtmFilter.replace(" ", "%20")
    response = requests.get(f"{rtmREST}?api_key={apiKey}&format=json&method=rtm.tasks.getList&filter={rtmFilter}&auth_token={authToken}&api_sig={apiSig}")
    response = response.text
    tasks = json.loads(response) # Parse response as JSON
    if "stat" in response:
        if tasks["rsp"]["stat"] == "ok":
            vim.command("silent! setlocal textwidth=0")
            vim.command("silent! 1,$d")
            tl = tasks["rsp"]["tasks"]["list"]
            for i in range(len(tl)):
                if i > 0:
                    vim.command("normal! o")
                lsID = tl[i]['id']
                vim.command("normal! oList ID: " + lsID + " - " + RTM_GetListName(lsID))
                ts = tl[i]['taskseries']
                for t in range(len(ts)):
                    vim.command("normal! o" + ts[t]['id'] + " - " + ts[t]['name'])
            vim.command("echo ''")
        else:
            # TODO: Handle it gracefully
            print("Something went wrong. We got this response from RTM when calling its API.")
            print(json.dumps())
    else:
        # TODO: Handle it gracefully
        print("Something went wrong with the CURL command.")
        print(response)

RTM_PrintTasksList(rtmFilter)
