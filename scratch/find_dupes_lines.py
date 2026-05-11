
import re

def find_duplicates():
    with open('/Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/core/translations.dart', 'r') as f:
        lines = f.readlines()

    content = "".join(lines)
    # Find each language block
    blocks = re.finditer(r"'([a-z]{2})':\s*\{", content)
    
    all_dupes_to_remove = []
    
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
        
        # Get the lines corresponding to this block
        block_start_line = content[:block.start()].count('\n') + 1
        block_end_line = content[:end_idx].count('\n') + 1
        
        block_lines = lines[block_start_line-1:block_end_line]
        
        seen_keys = {}
        for i, line in enumerate(block_lines):
            # Match 'key':
            m = re.search(r"['\"]([^'\"]+)['\"]\s*:", line)
            if m:
                key = m.group(1)
                line_num = block_start_line + i
                if key in seen_keys:
                    all_dupes_to_remove.append((line_num, key, lang))
                else:
                    seen_keys[key] = line_num
                    
    for line_num, key, lang in all_dupes_to_remove:
        print(f"DELETE LINE {line_num}: key='{key}' in lang='{lang}'")

if __name__ == '__main__':
    find_duplicates()
