
import re

def find_truly_dangling_strings():
    path = '/Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/core/translations.dart'
    with open(path, 'r') as f:
        lines = f.readlines()

    # Only check inside _translations map
    map_started = False
    in_lang_block = False
    
    for i, line in enumerate(lines):
        trimmed = line.strip()
        if 'const Map<String, Map<String, String>> _translations = {' in line:
            map_started = True
            continue
        if not map_started: continue
        
        # Detect end of _translations
        if trimmed == '};' and not in_lang_block:
            break
            
        # Detect language blocks like 'en': {
        if re.match(r"^\s*['\"][a-z]{2}['\"]\s*:\s*\{", line):
            in_lang_block = True
            continue
            
        if in_lang_block:
            if trimmed == '},':
                in_lang_block = False
                continue
                
            if not trimmed: continue
            if trimmed.startswith('//'): continue
            
            # If line is a string but doesn't have a colon
            if (trimmed.startswith("'") or trimmed.startswith('"')) and ':' not in trimmed:
                # Check if previous non-empty, non-comment line ended with a colon
                prev_idx = i - 1
                is_value_continuation = False
                while prev_idx >= 0:
                    prev_trimmed = lines[prev_idx].strip()
                    if not prev_trimmed or prev_trimmed.startswith('//'):
                        prev_idx -= 1
                        continue
                    if prev_trimmed.endswith(':'):
                        is_value_continuation = True
                    break
                
                if not is_value_continuation:
                    print(f"TRULY DANGLING - Line {i+1}: {trimmed}")

if __name__ == '__main__':
    find_truly_dangling_strings()
