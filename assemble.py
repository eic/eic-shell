#!/usr/bin/env python3
"""Assemble a standalone install.sh from the source install.sh and template files.

This script replaces envsubst calls that read from external template files with
equivalent inline heredoc-based calls, producing a self-contained install.sh
suitable for distribution (e.g., via curl | bash).

Usage:
    python3 assemble.py [SOURCE_DIR]

Output is written to stdout.
"""

import re
import sys
from pathlib import Path


def assemble(source_dir: Path) -> str:
    install_sh = (source_dir / 'install.sh').read_text()

    # Remove the SCRIPT_DIR assignment line (not needed in assembled version)
    install_sh = re.sub(
        r'\nSCRIPT_DIR=.*\n',
        '\n',
        install_sh,
    )

    # Replace each envsubst call that reads from a $SCRIPT_DIR template file
    # with an inline heredoc-based equivalent.
    #
    # Source pattern (single line):
    #   envsubst 'VARS' < "$SCRIPT_DIR/TEMPLATE_FILE" > OUTPUT
    #
    # Assembled replacement:
    #   envsubst 'VARS' > OUTPUT << 'HEREDOC_MARKER'
    #   <template content>
    #   HEREDOC_MARKER
    def inline_template(match):
        indent = match.group('indent')
        variables = match.group('variables')
        template_name = match.group('template')
        output = match.group('output')

        template_content = (source_dir / template_name).read_text()
        # Normalize to exactly one trailing newline so the heredoc closing
        # marker always appears on its own line
        template_content = template_content.rstrip('\n') + '\n'
        # Derive a safe heredoc marker from the template filename
        marker = template_name.upper().replace('-', '_').replace('.', '_')

        return (
            f"{indent}envsubst '{variables}' > {output} << '{marker}'\n"
            f"{template_content}"
            f"{marker}"
        )

    install_sh = re.sub(
        r'(?P<indent>[ \t]*)envsubst \'(?P<variables>[^\']+)\''
        r' < "\$SCRIPT_DIR/(?P<template>[^"]+)" > (?P<output>\S+)',
        inline_template,
        install_sh,
    )

    return install_sh


if __name__ == '__main__':
    source_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('.')
    sys.stdout.write(assemble(source_dir))
