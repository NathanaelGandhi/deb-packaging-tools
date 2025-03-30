import argparse


def _parse_known_args(
    argv: list[str] | None = None,
) -> tuple[argparse.Namespace, list[str]]:
    # - ng-debpkg level
    parser = argparse.ArgumentParser(description="Debian packaging tools.")
    subparsers = parser.add_subparsers(
        title="debpkg command", dest="ng_debpkg", required=True
    )
    subparsers.add_parser(
        "bootstrap", help="Bootstrap a deb package build with debian files."
    )
    build_parser = subparsers.add_parser("build", help="Build a package from a dir.")
    # -- build level
    build_subparsers = build_parser.add_subparsers(
        title="build command", dest="build", required=True
    )
    binary_parser = build_subparsers.add_parser("binary", help="Binary only build.")
    source_parser = build_subparsers.add_parser("source", help="Source only build.")
    # --- binary level
    binary_parser.add_argument(
        "-s",
        "--source",
        action="store_true",
        help="Build the source package in addition to the other requested build artifacts.",
    )

    return parser.parse_known_args(argv)  # return args, remaining_args


def main(argv: list[str] | None = None) -> None:
    print("Hello from ngtools-dpkg!")

    args, remaining_args = _parse_known_args(argv)

    if args.ng_debpkg == "bootstrap":
        from . import config_package

        config_package.main(remaining_args)
    elif args.ng_debpkg == "build":
        if args.build == "binary":
            from . import build_package_binary

            if args.source:
                # source & build
                build_package_binary.main_with_source(remaining_args)
            else:
                build_package_binary.main(remaining_args)
        elif args.build == "source":
            from . import build_package_source

            build_package_source.main(remaining_args)
