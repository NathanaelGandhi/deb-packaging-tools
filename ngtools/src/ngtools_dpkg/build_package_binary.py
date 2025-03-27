#!/usr/bin/env python3

import argparse
import os
import subprocess

from ngtools_dpkg.common import env_args_list_to_dict

def _parse_args(argv=None) -> argparse.Namespace:
  parser = argparse.ArgumentParser(description='Build a binary deb from a dir.')
  parser.add_argument('--cwd', type=str, default=os.getcwd(),
                      help='specify the working directory (default: current directory)')
  # Define 'env' as a list of strings, each in the format KEY=VALUE
  parser.add_argument('--env', type=str, action='append',  # Allows multiple environment variables to be passed
                      help='Set environment variables, in the form KEY=VALUE')
  parser.add_argument('--local', action='store_true',
                      help='build a local binary deb from a dir.')
#   parser.add_argument('--no-clean', action='store_true',
#                       help='do not run dh_clean')
#   parser.add_argument('--no-lintian', action='store_true',
#                       help='do not run lintian on the source package')
#   parser.add_argument('--no-sign', action='store_true',
#                       help='do not sign the source package')
#   parser.add_argument('--upstream-tar', action='store_true',
#                       help='create a debian source package with an upstream tarball')
  return parser.parse_args(argv)

def local_binary_build(args: argparse.Namespace):
    cmd = ['debuild', '-b']

    # Run cmd
    print("Running cmd: '" + ' '.join(cmd) + "'")
    subprocess.check_call(cmd, cwd=args.cwd, env=env_args_list_to_dict(args.env))

def main(argv=None):
    args = _parse_args(argv)
    if args.local:
        local_binary_build(args)
    else:
        pass

if __name__ == "__main__":
    print("Hello from ngtools-dpkg.build_package_binary!")
    main()
