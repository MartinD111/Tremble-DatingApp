
import re

def find_keyless_strings():
    path = '/Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/core/translations.dart'
    with open(path, 'r') as f:
        lines = f.readlines()

    for i, line in enumerate(lines):
        trimmed = line.strip()
        if (trimmed.startswith("'") or trimmed.startswith('"')) and not trimmed.endswith(':') and not trimmed.endswith('{') and ':' not in trimmed:
            # Check if it's part of a multiline value (previous line should end with something other than , or { or [)
            if i > 0:
                prev_trimmed = lines[i-1].strip()
                if prev_trimmed.endswith(',') or prev_trimmed.endswith('{') or prev_trimmed.endswith('['):
                     print(f"Line {i+1}: {trimmed}")

if __name__ == '__main__':
    find_keyless_strings()
