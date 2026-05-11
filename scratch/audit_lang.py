
import re
import sys

def audit_language(lang_code):
    with open('/Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/core/translations.dart', 'r') as f:
        content = f.read()

    def get_dict(lang):
        # Find the block for the language
        # Match 'lang': { ... } until the first } at the same indentation level
        # Since the file is flat, we can just look for the next language or end of map
        start_pattern = rf"'{lang}':\s*\{{"
        match = re.search(start_pattern, content)
        if not match:
            return None
        
        start_idx = match.end()
        # Find matching closing brace
        brace_count = 1
        end_idx = start_idx
        while brace_count > 0 and end_idx < len(content):
            if content[end_idx] == '{':
                brace_count += 1
            elif content[end_idx] == '}':
                brace_count -= 1
            end_idx += 1
        
        raw = content[start_idx:end_idx-1]
        
        d = {}
        # Find all keys and values
        # This matches 'key' : 'value' where value can span multiple lines
        # and handle escaped quotes
        matches = re.finditer(r"['\"]([^'\"]+)['\"]\s*:\s*['\"]", raw)
        for m in matches:
            key = m.group(1)
            # Find the end of the string value
            val_start = m.end()
            val_end = val_start
            while val_end < len(raw):
                if raw[val_end] == "'" or raw[val_end] == '"':
                    # Check if escaped
                    if raw[val_end-1] != '\\':
                        break
                val_end += 1
            value = raw[val_start:val_end]
            d[key] = value
        return d

    en_dict = get_dict('en')
    target_dict = get_dict(lang_code)

    if not en_dict:
        print("EN block not found")
        return
    if not target_dict:
        print(f"{lang_code} block not found")
        return

    en_keys = set(en_dict.keys())
    target_keys = set(target_dict.keys())

    missing = sorted(list(en_keys - target_keys))
    fallbacks = []
    for k in (en_keys & target_keys):
        if en_dict[k] == target_dict[k] and len(en_dict[k]) > 3:
            if k in ['cm', 'ok', 'status', 'km', 'm', 'kg']:
                continue
            fallbacks.append(k)
    
    print(f"--- {lang_code.upper()} Audit ---")
    print(f"Total keys in EN: {len(en_keys)}")
    print(f"Total keys in {lang_code.upper()}: {len(target_keys)}")
    print(f"Missing: {len(missing)}")
    if len(missing) < 50:
        print(f"  Keys: {missing}")
    else:
        print(f"  Keys (first 50): {missing[:50]}...")
    print(f"Fallbacks: {len(fallbacks)}")
    print(f"  Keys: {sorted(fallbacks)}")

if __name__ == '__main__':
    if len(sys.argv) > 1:
        audit_language(sys.argv[1])
    else:
        print("Usage: python3 audit_lang.py <lang_code>")
