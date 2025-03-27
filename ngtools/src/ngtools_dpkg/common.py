import os

def env_args_list_to_dict(env_args_list: list[str]) -> dict[str, str]:
  # Convert the list of env vars (e.g., ["KEY1=VALUE1", "KEY2=VALUE2"]) to a dictionary
  env = os.environ.copy()  # Start with the current environment
  if env_args_list:
      for item in env_args_list:
          key, value = item.split('=', 1)
          env[key] = value

  return env
