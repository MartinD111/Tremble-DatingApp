
import re

def find_duplicates():
    with open('/Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/core/translations.dart', 'r') as f:
        content = f.read()

    # Find each language block
    blocks = re.finditer(r"'([a-z]{2})':\s*\{", content)
    
    for block in blocks:
        lang = block.group(1)
        start_idx = block.end()
        
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
        
        keys = []
        # Match 'key':
        key_matches = re.finditer(r"['\"]([^'\"]+)['\"]\s*:", raw)
        for km in key_matches:
            keys.append(km.group(1))
        
        seen = set()
        dupes = []
        for k in keys:
            if k in seen:
                dupes.append(k)
            seen.add(k)
        
        if dupes:
            print(f"Language '{lang}' has duplicates: {dupes}")

if __name__ == '__main__':
    find_duplicates()
