import subprocess
def run_shell_command(cmd):
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=120)
        return result.stdout if result.returncode == 0 else result.stderr
    except Exception as e:
        return f"Shell error: {e}"