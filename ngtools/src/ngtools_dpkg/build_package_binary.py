#!/usr/bin/env python3

import argparse
import os
import subprocess

from ngtools_dpkg.common import env_args_list_to_dict
from ngtools_dpkg.common import get_os_version_codename
from ngtools_dpkg.common import get_architecture


def _parse_args(argv=None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build a binary deb from a dir.")
    # common args
    parser.add_argument(
        "--cwd",
        type=str,
        default=os.getcwd(),
        help="specify the working directory (default: current directory)",
    )
    # Define 'env' as a list of strings, each in the format KEY=VALUE
    parser.add_argument(
        "--env",
        type=str,
        action="append",  # Allows multiple environment variables to be passed
        help="Set environment variables, in the form KEY=VALUE",
    )
    # local specific args
    local_parser = parser.add_argument_group("local", "local specific args")
    local_parser.add_argument(
        "--local", action="store_true", help="build a local binary deb from a dir."
    )
    # sbuild specific args
    sbuild_parser = parser.add_argument_group("sbuild", "sbuild specific args")
    sbuild_parser.add_argument(
        "--dist",
        type=str,
        default=f"{get_os_version_codename()}",
        help="specify the debian/ubuntu distribution to build the package for",
    )
    sbuild_parser.add_argument(
        "--chroot",
        type=str,
        default=f"{get_os_version_codename()}_{get_architecture()}",
        help="specify the chroot to build the package in",
    )
    sbuild_parser.add_argument(
        "--host_arch",
        type=str,
        default=f"{get_architecture()}",
        help="specify the host architecture to build the package for",
    )
    sbuild_parser.add_argument(
        "--build_arch",
        type=str,
        default=f"{get_architecture()}",
        help="specify the build architecture to build the package on",
    )
    sbuild_parser.add_argument(
        "-j",
        "--jobs",
        type=int,
        default=8,
        help="specify the number of jobs to run in parallel (default: 8)",
    )
    sbuild_parser.add_argument(
        "-s",
        "--source",
        action="store_true",
        help="Build the source package in addition to the other requested build artifacts.",
    )
    sbuild_parser.add_argument(
        "--verbose", action="store_true", help="enable verbose output"
    )
    #   parser.add_argument('--no-clean', action='store_true',
    #                       help='do not run dh_clean')
    sbuild_parser.add_argument(
        "--no-lintian",
        action="store_true",
        help="do not run lintian on the source package",
    )
    sbuild_parser.add_argument(
        "--no-sign", action="store_true", help="do not sign the source package"
    )
    sbuild_parser.add_argument(
        "--no-check-builddeps",
        action="store_true",
        help="do not check build dependencies",
    )
    #   parser.add_argument('--upstream-tar', action='store_true',
    #                       help='create a debian source package with an upstream tarball')
    return parser.parse_args(argv)


def local_binary_build(args: argparse.Namespace):
    cmd = ["debuild", "-b"]

    # Run cmd
    print("Running cmd: '" + " ".join(cmd) + "'")
    subprocess.check_call(cmd, cwd=args.cwd, env=env_args_list_to_dict(args.env))


def sbuild_binary_build(args: argparse.Namespace):
    # verify arg: --dist            #TODO
    # verify arg: --chroot          #TODO
    # verify arg: --host_arch       #TODO
    # verify arg: --build_arch      #TODO

    # https://manpages.debian.org/buster/sbuild/sbuild.1.en.html
    # Note: Build architecture (Arch we are building on). Host architecture (Arch we are building for)
    # Example (bash):
    #    sbuild \
    #      --dist="$os_codename" \
    #      --chroot="$chroot" \
    #      --host="$arch_host" \
    #      --build="$arch_build" \
    #      -j8 \
    #      --source \
    #      --verbose \
    #      --build-dir=build_deb \
    #      --no-run-lintian \
    #      --debbuildopt=--no-check-builddeps --debbuildopt=--no-sign

    cmd = ["sbuild"]
    if args.dist:
        cmd.append("--dist=" + args.dist)
    if args.chroot:
        cmd.append("--chroot=" + args.chroot)
    if args.host_arch:
        cmd.append("--host=" + args.host_arch)
    if args.build_arch:
        cmd.append("--build=" + args.build_arch)
    if args.jobs:
        cmd.append("-j" + str(args.jobs))
    if args.source:
        cmd.append("--source")
    if args.verbose:
        cmd.append("--verbose")
    if args.no_lintian:
        cmd.append("--no-run-lintian")
    if args.no_sign:
        cmd.append("--debbuildopt=--no-sign")
    if args.no_check_builddeps:
        cmd.append("--debbuildopt=--no-check-builddeps")

    # Run cmd
    print("Running cmd: '" + " ".join(cmd) + "'")
    subprocess.check_call(cmd, cwd=args.cwd, env=env_args_list_to_dict(args.env))


def main_with_source(argv: list[str] | None = None) -> None:
    argv.append("--source")
    main(argv)


def main(argv: list[str] | None = None) -> None:
    args = _parse_args(argv)
    if args.local:
        local_binary_build(args)
    else:
        sbuild_binary_build(args)  # default build via sbuild


if __name__ == "__main__":
    print("Hello from ngtools-dpkg.build_package_binary!")
    main()
