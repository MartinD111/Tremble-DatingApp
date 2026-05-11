
import re

def find_keyless_strings():
    path = '/Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/core/translations.dart'
    with open(path, 'r') as f:
        lines = f.readlines()

    content = "".join(lines)
    # Find the _translations map
    map_match = re.search(r"const Map<String, Map<String, String>> _translations = \{", content)
    if not map_match:
        return
    
    map_start_idx = map_match.end()
    
    # Find matching closing brace for the whole map
    brace_count = 1
    idx = map_start_idx
    while brace_count > 0 and idx < len(content):
        if content[idx] == '{':
            brace_count += 1
        elif content[idx] == '}':
            brace_count -= 1
        idx += 1
    
    map_end_idx = idx
    map_content = content[map_start_idx:map_end_idx]
    map_start_line = content[:map_start_idx].count('\n') + 1
    
    map_lines = map_content.split('\n')
    
    for i, line in enumerate(map_lines):
        trimmed = line.strip()
        if not trimmed: continue
        if trimmed.startswith('//'): continue
        if trimmed.startswith('}'): continue
        
        # Check if it looks like a string without a key
        if (trimmed.startswith("'") or trimmed.startswith('"')) and ':' not in trimmed:
             # Could be part of a multiline string? 
             # In this file, mostly single line entries.
             print(f"Line {map_start_line + i}: {trimmed}")

if __name__ == '__main__':
    find_keyless_strings()
