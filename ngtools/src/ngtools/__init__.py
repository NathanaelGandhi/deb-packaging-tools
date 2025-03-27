import argparse

def _parse_known_args(argv=None) -> tuple[argparse.Namespace, list[str]]:
    parser = argparse.ArgumentParser(description='Collection of personal tools.')
    subparsers = parser.add_subparsers(title='commands', dest='command', required=True)
    subparsers.add_parser('dpkg')

    return parser.parse_known_args(argv)

def main(argv=None) -> None:
    print("Hello from ngtools!")

    args, remaining_args = _parse_known_args(argv)

    if args.command == 'dpkg':
        import ngtools_dpkg
        ngtools_dpkg.main(remaining_args)