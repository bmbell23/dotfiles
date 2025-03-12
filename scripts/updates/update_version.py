#!/usr/bin/env python3
"""Version update utility for dotfiles project."""

import sys
import re
from pathlib import Path
import argparse

def update_version_in_file(file_path: Path, new_version: str) -> bool:
    """Update version number in a file."""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Different patterns for different file types
    patterns = {
        'CHANGELOG.md': r'## \[([\d.]+)\]',
        'README.md': r'Version: ([\d.]+)',
        # Add more patterns as needed
    }

    pattern = patterns.get(file_path.name)
    if not pattern:
        return False

    updated = re.sub(pattern, lambda m: m.group(0).replace(m.group(1), new_version), content)
    
    if updated != content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(updated)
        return True
    return False

def main():
    parser = argparse.ArgumentParser(description='Update version numbers in project files')
    parser.add_argument('--update', help='New version number')
    parser.add_argument('--check', action='store_true', help='Check current versions')
    args = parser.parse_args()

    project_root = Path(__file__).parent.parent.parent
    files_to_update = [
        project_root / 'CHANGELOG.md',
        project_root / 'README.md',
        # Add more files as needed
    ]

    if args.update:
        for file_path in files_to_update:
            if file_path.exists():
                if update_version_in_file(file_path, args.update):
                    print(f"Updated version in {file_path.name}")
                else:
                    print(f"No version pattern found in {file_path.name}")

if __name__ == '__main__':
    sys.exit(main())