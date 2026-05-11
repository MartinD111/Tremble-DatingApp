
import re

def audit_all_keys():
    path = '/Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/core/translations.dart'
    with open(path, 'r') as f:
        lines = f.readlines()

    all_keys = set()
    lang_keys = {}
    current_lang = None
    map_started = False
    
    for line in lines:
        if '_translations = {' in line:
            map_started = True
            continue
        if not map_started: continue
        
        lang_match = re.search(r"^\s*['\"]([a-z]{2})['\"]\s*:\s*\{", line)
        if lang_match:
            current_lang = lang_match.group(1)
            lang_keys[current_lang] = set()
            continue
            
        if current_lang:
            if line.strip() == '},':
                current_lang = None
                continue
            
            key_match = re.search(r"^\s*['\"](.+?)['\"]\s*:", line)
            if key_match:
                key = key_match.group(1)
                all_keys.add(key)
                lang_keys[current_lang].add(key)

    for lang, keys in lang_keys.items():
        missing = all_keys - keys
        if missing:
            print(f"Language {lang} is missing keys: {missing}")

if __name__ == '__main__':
    audit_all_keys()
