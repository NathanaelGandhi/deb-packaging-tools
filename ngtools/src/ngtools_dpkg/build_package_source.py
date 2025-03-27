#!/usr/bin/env python3

import argparse
import os
import subprocess

from ngtools_dpkg.common import env_args_list_to_dict

def _parse_args(argv=None) -> argparse.Namespace:
  parser = argparse.ArgumentParser(description='Build a source deb from a dir.')
  parser.add_argument('--cwd', type=str, default=os.getcwd(),
                      help='specify the working directory (default: current directory)')
  # Define 'env' as a list of strings, each in the format KEY=VALUE
  parser.add_argument('--env', type=str, action='append',  # Allows multiple environment variables to be passed
                      help='Set environment variables, in the form KEY=VALUE')
  parser.add_argument('--no-clean', action='store_true',
                      help='do not run dh_clean')
  parser.add_argument('--no-lintian', action='store_true',
                      help='do not run lintian on the source package')
  parser.add_argument('--no-sign', action='store_true',
                      help='do not sign the source package')
  parser.add_argument('--upstream-tar', action='store_true',
                      help='create a debian source package with an upstream tarball')
  return parser.parse_args(argv)

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

  # Run cmd
  print("Running cmd: '" + ' '.join(cmd) + "'")
  subprocess.check_call(cmd, cwd=args.cwd, env=env_args_list_to_dict(args.env))

def main(argv=None):
  args = _parse_args(argv)
  build_source_deb(args)

if __name__ == "__main__":
    print("Hello from ngtools-dpkg.build_package_source!")
    main()