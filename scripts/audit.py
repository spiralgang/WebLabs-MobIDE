import time, json
def log_action(action, params):
    entry = {"ts": time.time(), "action": action, "params": params}
    with open("agent_audit.log", "a") as f:
        f.write(json.dumps(entry) + "\n")