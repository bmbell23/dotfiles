# dotfiles

Personal Linux configuration files and system setup tools.

## Features

### Package Management System
The `pkg` command provides a unified interface for managing packages across different Linux distributions:

```bash
# Check for missing packages
pkg check

# Add a new package
pkg add <package-name>

# Remove a package
pkg remove <package-name>

# Update package list from system
pkg update

# Install all missing packages
pkg install
```

Supported package managers:
- apt (Debian/Ubuntu)
- dnf (Fedora)
- yum (RHEL/CentOS)
- pacman (Arch)

Package list is maintained in `packages/packages.txt`.

### Git Version Control Helper
The `gvc` command simplifies versioned commits:

```bash
# Create versioned commit and tag
gvc "1.0.0" "Your commit message"
```

This will:
1. Add all changes
2. Create a commit with version prefix
3. Create an annotated tag
4. Push changes and tags

### Utility Functions
- `mkcd`: Create directory and change into it
  ```bash
  mkcd new-directory
  ```

## Cron Management System
The `cron` command provides a unified interface for managing cron jobs:

```bash
# Check for missing cron jobs
cron check

# Install all missing cron jobs
cron install
```

Cron jobs are defined in `cron/crontab.txt` using the format:
```bash
<schedule> <command> # <description>
```

Example:
```bash
0 9 * * * /path/to/script.sh # Daily morning backup
```

## Quick Start

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/projects/dotfiles
   ```

2. Run the installation script:
   ```bash
   cd ~/projects/dotfiles
   ./install.sh
   ```

3. Source your new configuration:
   ```bash
   source ~/.bashrc
   ```

## Project Structure

```
dotfiles/
├── bashrc/
│   ├── conf.d/            # Configuration modules
│   │   ├── 10-aliases.sh  # Alias definitions
│   │   ├── 20-functions.sh# Shell functions
│   │   └── 30-package-management.sh
│   ├── main.bashrc        # Main bashrc file
│   ├── local.sh          # Machine-specific settings (gitignored)
│   └── local.sh.example  # Template for local settings
├── packages/
│   ├── packages.txt      # Package list
│   └── install_packages.sh
└── install.sh           # Setup script
```

## Configuration

### Local Settings
Machine-specific configurations go in `bashrc/local.sh`:
1. Copy the example file:
   ```bash
   cp bashrc/local.sh.example bashrc/local.sh
   ```
2. Edit `local.sh` with your specific settings

### Package Management
1. Add packages to `packages/packages.txt`
2. Run `pkg check` to verify installation status
3. Run `pkg install` to install missing packages

## Development

### Adding New Features
1. Create feature branch:
   ```bash
   git checkout -b feature/new-feature
   ```
2. Make changes
3. Version and commit:
   ```bash
   gvc "1.1.0" "Added new feature"
   ```

### Version Control
- Use semantic versioning (X.Y.Z)
- Update CHANGELOG.md with changes
- Use `gvc` for versioned commits

## Maintenance

### Regular Updates
1. Update package list:
   ```bash
   pkg update
   ```
2. Check for missing packages:
   ```bash
   pkg check
   ```
3. Install updates:
   ```bash
   pkg install
   ```

### Troubleshooting
If you encounter issues:
1. Check `local.sh` for conflicts
2. Verify package manager detection
3. Ensure proper permissions
4. Check system compatibility

## Contributing
1. Fork the repository
2. Create feature branch
3. Make changes
4. Submit pull request

## License
[Add your chosen license here]

## Support
For issues and feature requests, please use the GitHub issue tracker.
