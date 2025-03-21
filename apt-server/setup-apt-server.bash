#!/bin/bash

### BASH SCRIPT SETUP ##############################################################################
# export DEBIAN_FRONTEND=noninteractive
declare -a repo_dir_list repo_codename_list repo_component_list
is_nginx=true
is_incoming=true
help_prompt=$(cat <<EOF
Usage: $0 [OPTIONS]

Options:
  -r, --repo <repo_base_dir> <codename> <component>   
                    Apt repo to create (default: $arch)
                      + Can be used multiple times 
                      + Examples: --repo ubuntu/my-repo noble main 
                                  --repo ubuntu/my/other-repo noble unstable
                      + Note: Above examples would be expected at http://your-server/ubuntu/my-repo 
                              & http://your-server/ubuntu/my/other-repo respectively
      --no-incoming No incoming ingest service setup
      --no-nginx    No nginx setup
  -h, --help        Show this help message and exit

Example:
  $0 -h

Notes:
---
EOF
)
while [[ "$#" -gt 0 ]]; do # Parse command line arguments and override defaults as required
    case $1 in
        # --special-arg) special_arg="$2"; shift ;;   # Handle `--<option> <value>`
        -r|--repo) 
          if [[ $# -lt 4 ]]; then
            echo "Error: $1 requires three arguments."
            echo "$help_prompt"
            exit 1
          fi
          repo_dir_list+=("$2"); repo_codename_list+=("$3"); repo_component_list+=("$4"); 
          shift 4 # Move past the three arguments
          ;;
        --no-incoming) is_incoming=false; shift ;;
        --no-nginx) is_nginx=false; shift ;;
        -h|--help) echo "$help_prompt"; exit 0 ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    #shellcheck disable=SC2317
    shift
done
echo "$help_prompt" # Always remind the user of this scripts usage
# Func runs given command with sudo if not already root, allows for running without
# sudo in a root context (ie. in docker containers). Falls back to sudo on error
# shellcheck disable=SC2015
function runSudo(){ [[ "${USER:-root}" == "root" ]] && "$@" || sudo "$@"; }
# set -x # print each command and its arguments as they are executed
### END BASH SCRIPT SETUP ##########################################################################

####################################################################################################

# 1. Setup nginx
if [[ $is_nginx == true ]]; then
  if ! [ -x "$(command -v nginx)" ]; then
      runSudo apt update
      runSudo apt install -y nginx
  fi

  # Disable standard default configuration
  if [ -L /etc/nginx/sites-enabled/default ]; then
    runSudo rm /etc/nginx/sites-enabled/default
  fi

  # Setup custom default configuration
  static_files_path="/var/www/public"
  symlink_path="$HOME/public"
  runSudo mkdir -p "$static_files_path"
  runSudo chmod 777 "$static_files_path"
  if [[ ! -L "$symlink_path" && ! -d "$static_files_path" ]]; then
    ln -s "$static_files_path" "$symlink_path"
  fi
  timestamp=$(date +"%Y%m%d-%H%M")
  echo -e "Host '$(hostname)' has been setup as a nginx web server on $timestamp using $(realpath "${BASH_SOURCE[0]}").\nhttp://$(hostname):80 is serving files from '${static_files_path}' with a helpful symlink at '${symlink_path}'." | sudo tee "${static_files_path}"/nginx-setup-on-"${timestamp}"
  cat << EOF | sudo tee /etc/nginx/conf.d/default.conf
server {
  listen 80 default_server;
  server_name _;

  root "$static_files_path";

  location / {
    # Enable directory listing
    autoindex on;  # Enable directory listing
    autoindex_exact_size off; # Display human-readable file sizes
    autoindex_localtime on;  # Display local time for files
    # First attempt to serve request as file, then
    # as directory, then fall back to 404.
    try_files \$uri \$uri/ =404;
  }
}
EOF

  # Restart nginx
  runSudo nginx -t # test the Nginx configuration for any syntax errors or misconfigurations.
  runSudo nginx -s reload
  runSudo systemctl restart nginx
else
  echo "nginx will not be installed"
fi # end [[ $is_nginx == true ]]

####################################################################################################

# TODO: 2. Setup repo's

####################################################################################################

# TODO: 3. Setup incoming_debs

####################################################################################################

echo "$0 FINISHED"
