# import utils
import vim
import datetime
import sys
import os
import traceback

plugin_root = vim.eval("s:plugin_root")
vim.command(f"py3file {plugin_root}/py/utils.py")

rtmREST = vim.eval("s:rtmREST")

apiKey = os.getenv("VIMODORO_RTM_API_KEY")
authToken = os.getenv("VIMODORO_RTM_TOKEN")
sharedSecret = os.getenv("VIMODORO_RTM_SECRET")

rtmFilter = vim.eval("rtmFilter")

def RTM_GetListName(listID):
    apiSig = RTM_Sign("api_key"+apiKey+"auth_token"+authToken+"formatjsonmethodrtm.lists.getList")
    params = {"api_key": apiKey, \
              "format": "json", \
              "method": "rtm.lists.getList", \
              "auth_token": authToken, \
              "api_sig": apiSig}
    response = RTM_request(params)
    lists = json.loads(response)
    if "stat" in response:
        if lists["rsp"]["stat"] == "ok":
            l = lists["rsp"]["lists"]["list"]
            for i in range(len(l)):
                if l[i]['id'] == listID:
                    return l[i]['name']
            return 'Err:Passed list ID not found' # Passed list ID not found.
        else:
            # TODO: Handle it gracefully.
            return 'Error'
    else:
        # TODO: Handle it gracefully.
        return 'Error'

def RTM_GetTasksList(rtmFilter):
    vim.command("echo '::Getting Tasks...'")
    vim.command("redraw")
    # let s:tasklist = {}
    vim.command("let s:tasklist = {}")
    apiSig = RTM_Sign("api_key"+apiKey+"auth_token"+authToken+"filter"+rtmFilter+"formatjsonmethodrtm.tasks.getList")
    params = {"api_key": apiKey, \
              "format": "json", \
              "method": "rtm.tasks.getList", \
              "filter": rtmFilter, \
              "auth_token": authToken, \
              "api_sig": apiSig}
    response = RTM_request(params)
    tasks = json.loads(response) # Parse response as JSON
    vdrIdx = 0
    tlKey = -1
    if "stat" in response:
        if tasks["rsp"]["stat"] == "ok":
            if "list" in tasks["rsp"]["tasks"]:
                tl = tasks["rsp"]["tasks"]["list"]
                for i in range(len(tl)):
                    tlKey += 1

                    if i > 0:
                        vim.command("let s:tasklist['" + str(tlKey) + "'] = {'type': 'blankline', 'label': ''}")
                        tlKey += 1

                    lsID = tl[i]['id']
                    # let s:tasklist['0'] = {'type': 'list', 'label': 'Personal'}
                    vim.command("let s:tasklist['" + str(tlKey) + "'] = {'type': 'list', 'label': '#" + RTM_GetListName(lsID) + "'}")

                    tlKey += 1
                    ts = tl[i]['taskseries']
                    # let s:tasklist['1'] = {'type': 'taskseries', 'tasks': {}}
                    vim.command("let s:tasklist['" + str(tlKey) + "'] = {'type': 'taskseries', 'tasks': {}}")

                    for t in range(len(ts)):
                        vdrIdx += 1
                        vdrKey = str(vdrIdx).zfill(3)
                        # let s:tasklist['1']['tasks']['001'] = {'lsID': 1, 'tsID': 2, 'ID': 3, 'label': 'blabla 1', 'completed': '2023-06-22T12:38:59Z'}
                        # let s:tasklist['1']['tasks']['002'] = {'lsID': 4, 'tsID': 5, 'ID': 6, 'label': 'blabla 2', 'completed'; ''}
                        vim.command("let s:tasklist['" + str(tlKey) + "']['tasks']['" + vdrKey + "'] = {" + \
                                    "'lsID': '" + lsID +"', " + \
                                    "'tsID': '" + ts[t]['id'] + "', " + \
                                    "'ID': '" + ts[t]['task'][0]['id'] + "', " + \
                                    "'label': '" + ts[t]['name'].replace("'", "''") + "', " + \
                                    "'completed': '" + ts[t]['task'][0]['completed'] + "'}")
            vim.command("let self.tasklistloaded = 1")
            vim.command("echo ''")
        else:
            print("Something went wrong. We got this response from RTM when calling its API.")
            print(response)
    else:
        # TODO: Handle it gracefully
        print("Something went wrong with the CURL command.")
        print(response)

RTM_GetTasksList(rtmFilter)
