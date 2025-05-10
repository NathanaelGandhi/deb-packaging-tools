#!/usr/bin/env python3

# Local binary build: 	debuild -b

import argparse
import os
import subprocess

def _parse_args():
  parser = argparse.ArgumentParser(description='Build a source deb from a dir.')
  parser.add_argument('--working-dir', '--cwd', type=str, default=os.getcwd(),
                      help='specify the working directory (default: current directory)')
  # Define 'env' as a list of strings, each in the format KEY=VALUE
  parser.add_argument('--env', type=str, action='append',  # Allows multiple environment variables to be passed
                      help='Set environment variables, in the form KEY=VALUE')
  parser.add_argument('--upstream-tar', action='store_true',
                      help='create a debian source package with an upstream tarball')
  parser.add_argument('--no-lintian', action='store_true',
                      help='do not run lintian on the source package')
  parser.add_argument('--no-clean', action='store_true',
                      help='do not run dh_clean')
  parser.add_argument('--no-sign', action='store_true',
                      help='do not sign the source package')
  return parser.parse_args()

def build_source_deb(args: argparse.Namespace):
   # Base command
  cmd = ['debuild']

  # To build a source package without running Lintian, run:
  # Note: The `--no-lintian` flag will only work in this case if it is first.
  if args.no_lintian:
    cmd.append('--no-lintian')

  # To build a source package *without* including the upstream tarball, run:
  cmd.append('-S')
  cmd.append('-d')

  # To build a source package *with* the upstream tarball, run:
  if args.upstream_tar:
    cmd.append('-sa')

  # To build a source package without running :manpage:`dh_clean(1)`, run:
  # Note: This tends to fix failures regarding missing build dependencies
  if args.no_clean:
    cmd.append('-nc')

  # To build a source package without a cryptographic signature (not recommended), run:
  if args.no_sign:
    cmd.append('-us')
    cmd.append('-uc')

  # Convert the list of env vars (e.g., ["KEY1=VALUE1", "KEY2=VALUE2"]) to a dictionary
  env = os.environ.copy()  # Start with the current environment
  if args.env:
      for item in args.env:
          key, value = item.split('=', 1)
          env[key] = value

  # Run cmd
  print("Running cmd: '" + ' '.join(cmd) + "'")
  # subprocess.check_call(cmd)
  subprocess.check_call(cmd, cwd=args.working_dir, env=env)

def main():
  args = _parse_args()
  build_source_deb(args)

if __name__ == "__main__":
    main()