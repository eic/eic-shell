#!/usr/bin/env python3
"""Assemble a standalone install.sh from the source install.sh and template files.

The source install.sh generates each launcher script in two steps:
  1. A variable-expanding heredoc writes a preamble with install-time values.
  2. ``tail -n +2 "$SCRIPT_DIR/TEMPLATE" >> OUTPUT`` appends the template body
     (skipping its ``#!/bin/bash`` shebang, which the preamble already provides).

This assembler replaces step 2 with an equivalent inline heredoc so the result
is a self-contained install.sh suitable for distribution (e.g., via curl | bash).

Jinja2's FileSystemLoader is used to locate and read each template file cleanly.

Usage:
    python3 assemble.py [SOURCE_DIR]

Output is written to stdout.
"""

import re
import sys
from pathlib import Path

from jinja2 import Environment, FileSystemLoader


def assemble(source_dir: Path) -> str:
    env = Environment(
        loader=FileSystemLoader(str(source_dir)),
        keep_trailing_newline=True,
    )

    install_sh = (source_dir / 'install.sh').read_text()

    # Remove the SCRIPT_DIR assignment line (not needed in the assembled version
    # because all template file references are replaced by inline heredocs below).
    install_sh = re.sub(r'SCRIPT_DIR=.*\n', '', install_sh, count=1)

    # Replace each ``tail -n +2 "$SCRIPT_DIR/TEMPLATE" >> OUTPUT`` call with an
    # inline heredoc containing the template body (all lines after the shebang).
    def inline_template(match: re.Match) -> str:
        indent = match.group('indent')
        template_name = match.group('template')
        output = match.group('output')

        # Load the template file via Jinja2's FileSystemLoader.
        template_source, _, _ = env.loader.get_source(env, template_name)
        # Skip the first line (#!/bin/bash shebang); the preamble heredoc that
        # precedes this call already provides the shebang in the assembled file.
        parts = template_source.split('\n', 1)
        template_body = parts[1].rstrip('\n') if len(parts) > 1 else ''

        # Derive a safe heredoc closing marker from the template filename.
        marker = template_name.upper().replace('-', '_').replace('.', '_')

        return (
            f"{indent}cat >> {output} << '{marker}'\n"
            f"{template_body}\n"
            f"{marker}"
        )

    install_sh = re.sub(
        r'(?P<indent>[ \t]*)tail -n \+2 "\$SCRIPT_DIR/(?P<template>[^"]+)" >> (?P<output>\S+)',
        inline_template,
        install_sh,
    )

    # Validate: no $SCRIPT_DIR references should remain after assembly.
    if '$SCRIPT_DIR/' in install_sh:
        raise RuntimeError(
            'Assembled install.sh still contains $SCRIPT_DIR/ references; '
            'the assembly pattern may have drifted from the source.'
        )

    return install_sh


if __name__ == '__main__':
    source_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('.')
    sys.stdout.write(assemble(source_dir))
