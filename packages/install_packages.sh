#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="${SCRIPT_DIR}/packages.txt"
PACKAGE_MANAGER=""

# Detect package manager
if command -v apt &> /dev/null; then
    PACKAGE_MANAGER="apt"
elif command -v dnf &> /dev/null; then
    PACKAGE_MANAGER="dnf"
elif command -v yum &> /dev/null; then
    PACKAGE_MANAGER="yum"
elif command -v pacman &> /dev/null; then
    PACKAGE_MANAGER="pacman"
else
    echo "No supported package manager found"
    exit 1
fi

# Function to check if a package is installed
is_installed() {
    local package=$1
    case $PACKAGE_MANAGER in
        "apt")
            dpkg -l "$package" &> /dev/null
            ;;
        "dnf"|"yum")
            rpm -q "$package" &> /dev/null
            ;;
        "pacman")
            pacman -Qi "$package" &> /dev/null
            ;;
    esac
    return $?
}

# Function to install a package
install_package() {
    local package=$1
    echo "Installing $package..."
    case $PACKAGE_MANAGER in
        "apt")
            sudo apt-get install -y "$package"
            ;;
        "dnf")
            sudo dnf install -y "$package"
            ;;
        "yum")
            sudo yum install -y "$package"
            ;;
        "pacman")
            sudo pacman -S --noconfirm "$package"
            ;;
    esac
}

# Function to add a new package to the list
add_package() {
    local package=$1
    if ! grep -q "^${package}$" "$PACKAGES_FILE"; then
        echo "$package" >> "$PACKAGES_FILE"
        echo "Added $package to packages.txt"
        sort -u -o "$PACKAGES_FILE" "$PACKAGES_FILE"
    fi
}

# Main installation function
install_packages() {
    local missing_packages=()
    
    # Read packages file, skipping comments and empty lines
    while read -r package; do
        [[ -z "$package" || "$package" =~ ^# ]] && continue
        if ! is_installed "$package"; then
            missing_packages+=("$package")
        fi
    done < "$PACKAGES_FILE"

    if [ ${#missing_packages[@]} -eq 0 ]; then
        echo "All packages are already installed!"
        return 0
    fi

    echo "The following packages will be installed:"
    printf '%s\n' "${missing_packages[@]}"
    
    read -p "Continue? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        case $PACKAGE_MANAGER in
            "apt")
                sudo apt-get update
                ;;
            "dnf"|"yum")
                sudo "$PACKAGE_MANAGER" check-update
                ;;
            "pacman")
                sudo pacman -Sy
                ;;
        esac

        for package in "${missing_packages[@]}"; do
            install_package "$package"
        done
    fi
}

# Command line interface
case "$1" in
    "check")
        # Just check what needs to be installed
        install_packages
        ;;
    "install")
        # Install missing packages
        install_packages
        ;;
    "add")
        if [ -z "$2" ]; then
            echo "Usage: $0 add <package-name>"
            exit 1
        fi
        # Add package and install it
        add_package "$2"
        install_package "$2"
        ;;
    *)
        echo "Usage: $0 {check|install|add <package-name>}"
        exit 1
        ;;
esac