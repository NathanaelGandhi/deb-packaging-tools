def check_py_deps(py_pkgs: list[str]):
    """
    Check if the specified Python packages are installed and available in the PATH.

    Args:
        py_pkgs: A list of package names as strings.

    Raises:
        EnvironmentError: If any of the specified packages are not installed
        or not found in the PATH.
    """

    import shutil

    for pkg in py_pkgs:
        if shutil.which(pkg) is None:
            # These should have been added as project deps and installed already
            raise EnvironmentError(f"{pkg} is not installed or not in the PATH.")


def check_and_install_dpkg_deps(dpkg_pkgs: list[str]):
    """
    Check if the specified Debian packages are installed and available in the PATH.

    If any of the packages are not installed, this function will install them using
    apt-get.

    Args:
        dpkg_pkgs: A list of package names as strings.

    Raises:
        EnvironmentError: If any of the specified packages are not installed
            or not found in the PATH.
    """
    import shutil
    import subprocess

    supported_distros = ["debian", "ubuntu", "raspbian"]
    try:
        with open("/etc/os-release") as f:
            os_info = f.read()
            # Check for keywords indicating a Debian-based system
            for distro in supported_distros:
                if distro in os_info.lower():
                    return
    except FileNotFoundError:
        raise EnvironmentError(
            f"This script can only be run on a supported system: {supported_distros}."
        )

    for pkg in dpkg_pkgs:
        if shutil.which(pkg) is None:
            print(f"{pkg} is not installed. Installing now...")
            subprocess.run(["sudo", "apt-get", "update"])
            subprocess.run(["sudo", "apt-get", "install", "-y", pkg])
            # Guard on successful application install
            if "install ok installed" in subprocess.run(
                ["dpkg-query", "-W", "-f=${Status}", pkg],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=True,
            ).stdout.decode("utf-8"):
                # true
                print(f"{pkg} was installed successfully.")
            else:
                # false
                raise EnvironmentError(f"{pkg} is not installed or not in the PATH.")
        else:
            print(f"{pkg} is already installed.")


def env_args_list_to_dict(env_args_list: list[str]) -> dict[str, str]:
    """
    Convert a list of environment variables to a dictionary.

    Args:
        env_args_list: A list of strings, where each string is in the format "KEY=VALUE".

    Returns:
        A dictionary containing all the environment variables from the list, with any
        variables from the current environment that are not in the list removed.
    """
    import os

    env = os.environ.copy()  # Start with the current environment
    if env_args_list:
        for item in env_args_list:
            key, value = item.split("=", 1)
            env[key] = value

    return env


def get_architecture():
    """
    Get the current Debian architecture.

    Returns:
        The Debian architecture as a string, or None if dpkg is not available.
    """
    import subprocess

    result = subprocess.run(
        ["dpkg", "--print-architecture"], text=True, capture_output=True
    )
    return result.stdout.strip() if result.returncode == 0 else None


def get_os_version_codename() -> str | None:
    """
    Get the current Debian version codename.

    This function reads the file /etc/os-release and returns the value of the
    VERSION_CODENAME field.

    Returns:
        The Debian version codename as a string, or None if the file is not
        readable.
    """
    try:
        with open("/etc/os-release") as f:
            for line in f:
                if line.startswith("VERSION_CODENAME"):
                    return line.split("=")[1].strip(' "').strip()
    except OSError:
        return None
