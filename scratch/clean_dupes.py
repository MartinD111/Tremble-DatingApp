
import re

def clean_translations():
    path = '/Users/aleksandarbojic/AMSSolutions/Tremble/Pulse---Dating-app/lib/src/core/translations.dart'
    with open(path, 'r') as f:
        lines = f.readlines()

    content = "".join(lines)
    blocks = re.finditer(r"'([a-z]{2})':\s*\{", content)
    
    lines_to_delete = set()
    
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
        
        block_start_line = content[:block.start()].count('\n') + 1
        block_end_line = content[:end_idx].count('\n') + 1
        
        block_lines = lines[block_start_line-1:block_end_line]
        
        seen_keys = set()
        for i, line in enumerate(block_lines):
            m = re.search(r"['\"]([^'\"]+)['\"]\s*:", line)
            if m:
                key = m.group(1)
                line_num = block_start_line + i
                if key in seen_keys:
                    lines_to_delete.add(line_num - 1) # 0-indexed for the list
                else:
                    seen_keys.add(key)
    
    new_lines = [line for i, line in enumerate(lines) if i not in lines_to_delete]
    
    with open(path, 'w') as f:
        f.writelines(new_lines)
    
    print(f"Removed {len(lines_to_delete)} duplicate keys.")

if __name__ == '__main__':
    clean_translations()
