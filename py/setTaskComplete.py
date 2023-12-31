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

#if len(sys.argv) < 3:
#    print("Usage: setTaskList.py <listID> <taskseriesID> <taskID>")
#else:
#    listID = sys.argv[1]
#    taskseriesID = sys.argv[2]
#    taskID = sys.argv[3]

listID = vim.eval("s:tasklist[tasklistKey]['tasks'][s:vdrId]['lsID']")
taskseriesID = vim.eval("s:tasklist[tasklistKey]['tasks'][s:vdrId]['tsID']")
taskID = vim.eval("s:tasklist[tasklistKey]['tasks'][s:vdrId]['ID']")

def RTM_Sign(params):
    return hashlib.md5((sharedSecret+params).encode()).hexdigest()

def RTM_CreateTimeline():
    apiSig = RTM_Sign("api_key"+apiKey+"auth_token"+authToken+"formatjsonmethodrtm.timelines.create")
    params = {"api_key": apiKey, \
              "format": "json", \
              "method": "rtm.timelines.create", \
              "auth_token": authToken, \
              "api_sig": apiSig}
    response = RTM_request(params)
    timelines = json.loads(response)
    if "stat" in response:
        if timelines["rsp"]["stat"] == "ok":
            return timelines["rsp"]["timeline"]
    else:
        # TODO: Handle it gracefully.
        return 'Error'

# Params needed by rtm.tasks.complete method:
# api_key
# auth_token
# format
# list_id
# method
# task_id
# taskseries_id
# timeline

def RTM_MarkTaskComplete(listID, taskseriesID, taskID):
    timeline = RTM_CreateTimeline()
    apiSig = RTM_Sign("api_key"+apiKey+"auth_token"+authToken+"formatjson"+"list_id"+listID+"methodrtm.tasks.complete"+"task_id"+taskID+"taskseries_id"+taskseriesID+"timeline"+timeline)
    params = {"api_key": apiKey, \
              "format": "json", \
              "method": "rtm.tasks.complete", \
              "auth_token": authToken, \
              "api_sig": apiSig, \
              "list_id": listID, \
              "task_id": taskID, \
              "taskseries_id": taskseriesID, \
              "timeline": timeline}
    response = RTM_request(params)
    tasks = json.loads(response) # Parse response as JSON
    if "stat" in response:
        if tasks["rsp"]["stat"] == "ok":
            vim.command("echo 'The task " + vim.eval("s:rtm_taskname").replace("'", "''")+ " has been marked as done.'")
            vim.command("redraw")
        else:
            # TODO: Handle it gracefully
            print("Something went wrong. We got this response from RTM when calling its API.")
            print(response)
    else:
        # TODO: Handle it gracefully
        print("Something went wrong with the CURL command.")
        print(response)

RTM_MarkTaskComplete(listID, taskseriesID, taskID)
