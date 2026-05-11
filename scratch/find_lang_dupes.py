
import re

def find_duplicates_in_lang(lang_code):
    path = '/Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/core/translations.dart'
    with open(path, 'r') as f:
        lines = f.readlines()

    map_started = False
    in_lang_block = False
    keys = []
    
    for i, line in enumerate(lines):
        trimmed = line.strip()
        if '_translations = {' in line:
            map_started = True
            continue
        if not map_started: continue
        
        # Detect language block
        lang_match = re.search(fr"['\"]{lang_code}['\"]\s*:\s*\{{", line)
        if lang_match:
            in_lang_block = True
            keys = []
            continue
            
        if in_lang_block:
            if trimmed == '},':
                in_lang_block = False
                continue
                
            # Find key
            key_match = re.search(r"^\s*['\"](.+?)['\"]\s*:", line)
            if key_match:
                key = key_match.group(1)
                if key in keys:
                    print(f"Duplicate key in {lang_code}: {key} at line {i+1}")
                keys.append(key)

if __name__ == '__main__':
    find_duplicates_in_lang('hu')
