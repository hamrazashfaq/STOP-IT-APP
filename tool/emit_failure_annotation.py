#!/usr/bin/env python3
"""Copy a failed Flutter/Gradle command's useful output into a GitHub annotation."""
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(encoding='utf-8', errors='replace')
text = text[-14000:]
text = text.replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A').replace(':', '%3A').replace(',', '%2C')
print(f'::error title=Flutter build output::{text}')
