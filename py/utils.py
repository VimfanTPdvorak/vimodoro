import json
import urllib.error
import urllib.request
import urllib.parse
import hashlib

class KnownError(Exception):
    pass

def RTM_request(params):
    # Encode the query parameters
    encoded_params = urllib.parse.urlencode(params)

    # Append the encoded parameters to the base URL
    url = f"{rtmREST}?{encoded_params}"

    try:
        response = urllib.request.urlopen(url)
        return response.read().decode('utf-8')
    except urllib.error.URLError as e:
        print(f"Error: {e.reason}")

def RTM_Sign(params):
    return hashlib.md5((sharedSecret+params).encode()).hexdigest()
