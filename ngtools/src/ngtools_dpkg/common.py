import os
import subprocess

def env_args_list_to_dict(env_args_list: list[str]) -> dict[str, str]:
    """
    Convert a list of environment variables to a dictionary.

    Args:
        env_args_list: A list of strings, where each string is in the format "KEY=VALUE".

    Returns:
        A dictionary containing all the environment variables from the list, with any
        variables from the current environment that are not in the list removed.
    """
    env = os.environ.copy()  # Start with the current environment
    if env_args_list:
        for item in env_args_list:
            key, value = item.split("=", 1)
            env[key] = value

    return env

def get_architecture():
    result = subprocess.run(
        ["dpkg", "--print-architecture"],
        text=True, capture_output=True
    )
    return result.stdout.strip() if result.returncode == 0 else None

get_os_version_codename = lambda: next((line.split("=")[1].strip(' "') for line in open("/etc/os-release") if line.startswith("VERSION_CODENAME")), None).strip()
