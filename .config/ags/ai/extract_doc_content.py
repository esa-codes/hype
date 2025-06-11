#!/usr/bin/env python
import sys
import textract
import os

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python extract_doc_content.py <file_path>", file=sys.stderr)
        sys.exit(1)

    file_path = sys.argv[1]

    if not os.path.exists(file_path):
        print(f"Error: File not found at {file_path}", file=sys.stderr)
        sys.exit(1)

    try:
        text = textract.process(file_path)
        print(text.decode('utf-8'))
    except Exception as e:
        print(f"Error processing file {file_path}: {e}", file=sys.stderr)
        sys.exit(1)