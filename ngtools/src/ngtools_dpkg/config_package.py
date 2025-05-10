#!/usr/bin/env python3

import argparse
import os
import re
import subprocess

from ngtools_dpkg.common import env_args_list_to_dict


def _parse_args(argv=None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build a source deb from a dir.")
    parser.add_argument(
        "--cwd",
        type=str,
        default=os.getcwd(),
        help="Specify the working directory (default: current directory)",
    )
    # Define 'env' as a list of strings, each in the format KEY=VALUE
    parser.add_argument(
        "--env",
        type=str,
        action="append",  # Allows multiple environment variables to be passed
        help="Set environment variables, in the form KEY=VALUE",
    )
    parser.add_argument(
        "--mode",
        type=str,
        default="dh_make",
        choices=["dh_make", "debian", "rosdebian"],
        help="Set the configure mode (generator) for the debian files",
    )
    parser.add_argument(
        "-p",
        type=str,
        default=None,
        help="Set the package name and version in the format of <package>_<version>",
    )
    parser.add_argument(
        "--no-upstream-source",
        action="store_true",
        help="do not expect an upstream source package",
    )

    return parser.parse_args(argv)

def _determine_package_name(cwd=None):
    if os.path.isfile(os.path.join(cwd, "debian", "control")):
        with open(os.path.join(cwd, "debian", "control"), "r") as f:
            for line in f:
                if line.startswith("Source: ") or line.startswith("Package: "):
                    return line.split(":")[1].strip().replace("_", "-")
    elif cwd is not None:
        return os.path.basename(cwd).replace("_", "-")
    else:
        raise ValueError("Could not determine package name.")
    
def _determine_package_name_version(cwd, package_name_version:str=None):
    if package_name_version is None:
        # determine from cwd
        if _is_valid_debian_package_name_version(os.path.basename(cwd)):
          package_name_version = os.path.basename(cwd)
        else:
          package_name = _determine_package_name(cwd=cwd)
          package_version = "0.0.1"
          package_name_version = f"{package_name}_{package_version}"

    # Guard on valid package name version string
    if _is_valid_debian_package_name_version(package_name_version) == False:
        raise ValueError("Package name and version must be in the format of <package>_<version>")

    return package_name_version
    
def _is_valid_debian_package_name_version(package_name_version: str=None):
    pattern = r"^[^_]+_\d+(\.\d+)*(-[\w.+~]+)?$"
    if package_name_version is not None:
      if re.match(pattern, package_name_version):
          return True
      else:
          print(f"Invalid format: {package_name_version}")
    else:
      print("No string provided")
    return False

def _dh_make_generator(package_name_version:str, cwd=None, env=None, check=True, upstream_source=True):
    cmd = ['dh_make'] # Initialise command
    cmd.append('-p')
    cmd.append(package_name_version)
    if upstream_source == False:
        cmd.append('--createorig')
    print(f"Running cmd: " + ' '.join(cmd))
    subprocess.run(cmd, check=check, cwd=cwd, env=env)
    pass


def _debian_generator(package_name_version:str, cwd=None, env=None, check=True):
    # setup debian/control
    pass


def _rosdebian_generator(cwd=None, env=None, check=True):
    cmd = ['bloom-generate'] # Initialise command
    cmd.append('rosdebian')
    cmd.append('.')
    print(f"Running cmd: " + ' '.join(cmd))
    subprocess.run(cmd, check=check, cwd=cwd, env=env)
    pass


def main(argv: list[str] | None = None) -> None:
    args = _parse_args(argv)

    if args.mode:
      print(f"Configure mode (generator): {args.mode}")
    if args.mode == "dh_make":
        _dh_make_generator(_determine_package_name_version(args.cwd, args.p), cwd=args.cwd, env=env_args_list_to_dict(args.env), upstream_source=not args.no_upstream_source)
    elif args.mode == "debian":
        _debian_generator(_determine_package_name_version(args.cwd, args.p), cwd=args.cwd, env=env_args_list_to_dict(args.env))
    elif args.mode == "rosdebian":
        _rosdebian_generator(cwd=args.cwd, env=env_args_list_to_dict(args.env))


if __name__ == "__main__":
    print("Hello from ngtools-dpkg.configure!")
    main()