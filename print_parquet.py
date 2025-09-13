#!/usr/bin/env python3
"""
Script to print the contents of parquet and ORC files.
Usage: python print_parquet.py <path_to_file>
"""

import sys
import pandas as pd
import argparse
from pathlib import Path


def detect_file_format(file_path):
    """
    Detect the file format based on extension.

    Args:
        file_path (str): Path to the file

    Returns:
        str: File format ('parquet' or 'orc')
    """
    file_ext = Path(file_path).suffix.lower()
    if file_ext == '.parquet':
        return 'parquet'
    elif file_ext == '.orc':
        return 'orc'
    else:
        # Try to detect by attempting to read as parquet first
        try:
            pd.read_parquet(file_path, nrows=1)
            return 'parquet'
        except Exception as e:
            print(f"Error reading Parquet file: {e}")
            try:
                pd.read_orc(file_path)
                return 'orc'
            except Exception as e:
                print(f"Error reading ORC file: {e}")
                raise ValueError(f"Unsupported file format. Expected .parquet or .orc file, got: {file_ext}")


def print_file_contents(file_path, max_rows=None, show_info=True):
    """
    Print the contents of a parquet or ORC file.

    Args:
        file_path (str): Path to the file
        max_rows (int): Maximum number of rows to display (None for all)
        show_info (bool): Whether to show file information
    """
    try:
        # Detect file format
        file_format = detect_file_format(file_path)

        # Read the file based on format
        if file_format == 'parquet':
            df = pd.read_parquet(file_path)
        elif file_format == 'orc':
            df = pd.read_orc(file_path)

        if show_info:
            print(f"File: {file_path}")
            print(f"Format: {file_format.upper()}")
            print(f"Shape: {df.shape[0]} rows × {df.shape[1]} columns")
            print(f"Columns: {list(df.columns)}")
            print("-" * 80)

        # Display the data
        if max_rows is not None:
            print(f"Showing first {min(max_rows, len(df))} rows:")
            print(df.head(max_rows).to_string(index=True))
        else:
            print("All data:")
            print(df.to_string(index=True))

    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found.")
        sys.exit(1)
    except Exception as e:
        print(f"Error reading file: {e}")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="Print the contents of parquet and ORC files",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python print_parquet.py data.parquet
  python print_parquet.py data.orc
  python print_parquet.py data.parquet --max-rows 10
  python print_parquet.py data.orc --no-info
        """
    )

    parser.add_argument(
        "file_path",
        help="Path to the parquet or ORC file"
    )

    parser.add_argument(
        "--max-rows", "-n",
        type=int,
        default=None,
        help="Maximum number of rows to display (default: all rows)"
    )

    parser.add_argument(
        "--no-info",
        action="store_true",
        help="Don't show file information"
    )

    args = parser.parse_args()

    # Check if file exists
    if not Path(args.file_path).exists():
        print(f"Error: File '{args.file_path}' does not exist.")
        sys.exit(1)

    # Print the file contents
    print_file_contents(
        args.file_path,
        max_rows=args.max_rows,
        show_info=not args.no_info
    )


if __name__ == "__main__":
    main()
