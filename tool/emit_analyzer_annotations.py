#!/usr/bin/env python3
"""Mirror Dart analyzer --machine diagnostics into GitHub check annotations."""
import sys
from pathlib import Path


def escape(value: str) -> str:
    return value.replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A').replace(':', '%3A').replace(',', '%2C')

path = Path(sys.argv[1])
count = 0
for line in path.read_text(encoding='utf-8', errors='replace').splitlines():
    fields = line.split('|', 8)
    if len(fields) < 8 or fields[0] not in {'ERROR', 'WARNING', 'INFO'}:
        continue
    severity, code, _package, file, row, column, _length, message = fields[:8]
    correction = fields[8] if len(fields) > 8 else ''
    level = 'error' if severity == 'ERROR' else 'warning' if severity == 'WARNING' else 'notice'
    location = f'file={escape(file)},line={row},col={column}'
    detail = f'[{code}] {message}' + (f' — {correction}' if correction else '')
    print(f'::{level} {location}::{escape(detail)}')
    count += 1
if count == 0:
    raw = path.read_text(encoding='utf-8', errors='replace')
    if 'No issues found!' in raw:
        print('::notice title=Flutter analysis::No issues found.')
    else:
        output = escape(raw[:12000])
        print(f'::error title=Analyzer raw output::{output}')
