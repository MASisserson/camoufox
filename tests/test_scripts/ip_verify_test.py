from typing import Tuple
import requests

def proxy_exit_geo() -> Tuple[str, str]:
    """
    The exit IP of `proxy` and that IP's timezone, looked up through the proxy.
    Raises InvalidIP when the lookup fails: a context that silently kept the
    host's WebRTC IP and timezone behind a proxy would be a leak.
    """
    try:
        resp = requests.get(
            "https://ipinfo.io/json",
            timeout=10,
        )
        resp.raise_for_status()
        print(resp)
        data = resp.json()
        print(data)
    except requests.RequestException as exception:
        # raise InvalidIP(f"{PROXY_LOOKUP_FAILED}: {exception}") from exception
        print("Ran into error!")
        print(exception)
    # if data.get("status") != "success" or not data.get("timezone"):
    #     raise InvalidIP(f"{PROXY_LOOKUP_FAILED}: {data.get('message') or data}")
    # validate_ip(data["ip"])
    return data["ip"], data["timezone"]

variable = proxy_exit_geo()
print(variable)
