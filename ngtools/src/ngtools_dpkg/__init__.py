import argparse

def _parse_known_args(argv=None) -> tuple[argparse.Namespace, list[str]]:
    parser = argparse.ArgumentParser(description='Build a debian package (source or binary) from a dir.')
    subparsers = parser.add_subparsers(dest='command', required=True)
    subparsers.add_parser('source')
    subparsers.add_parser('binary')

    return parser.parse_known_args(argv)

def main(argv=None) -> None:
    print("Hello from ngtools-dpkg!")
    
    args, remaining_args = _parse_known_args(argv)

    if args.command == 'source':
        import ngtools_dpkg.build_package_source
        ngtools_dpkg.build_package_source.main(remaining_args)
    elif args.command == 'binary':
        import ngtools_dpkg.build_package_binary
        ngtools_dpkg.build_package_binary.main(remaining_args)
