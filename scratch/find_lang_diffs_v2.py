
import re
import sys

def find_extra_keys(lang_code):
    path = '/Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/core/translations.dart'
    with open(path, 'r') as f:
        lines = f.readlines()

    map_started = False
    en_keys = set()
    lang_keys = set()
    current_lang = None
    
    for line in lines:
        if '_translations = {' in line:
            map_started = True
            continue
        if not map_started: continue
        
        # Detect language block
        lang_match = re.search(r"^\s*['\"]([a-z]{2})['\"]\s*:\s*\{", line)
        if lang_match:
            current_lang = lang_match.group(1)
            continue
            
        if current_lang:
            if line.strip() == '},':
                current_lang = None
                continue
            
            # Find key
            key_match = re.search(r"^\s*['\"](.+?)['\"]\s*:", line)
            if key_match:
                key = key_match.group(1)
                if current_lang == 'en':
                    en_keys.add(key)
                elif current_lang == lang_code:
                    lang_keys.add(key)

    extra = lang_keys - en_keys
    print(f"Extra keys in {lang_code}: {extra}")
    missing = en_keys - lang_keys
    print(f"Missing keys in {lang_code}: {missing}")

if __name__ == '__main__':
    lang = sys.argv[1] if len(sys.argv) > 1 else 'hu'
    find_extra_keys(lang)
