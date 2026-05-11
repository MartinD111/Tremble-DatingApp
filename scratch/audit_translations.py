
import re
import json

def audit_translations():
    with open('lib/src/core/translations.dart', 'r') as f:
        content = f.read()

    # Find the _translations map
    match = re.search(r'const Map<String, Map<String, String>> _translations = \{(.*?)\};', content, re.DOTALL)
    if not match:
        print("Could not find _translations map")
        return

    translations_body = match.group(1)
    
    # Split by language keys
    lang_blocks = re.split(r"  '([a-z]{2})': \{", translations_body)
    
    # The first element is empty or whitespace
    # Subsequent elements are (lang_code, content, lang_code, content, ...)
    langs = {}
    for i in range(1, len(lang_blocks), 2):
        lang_code = lang_blocks[i]
        block_content = lang_blocks[i+1]
        
        # Extract keys
        keys = re.findall(r"    '([a-zA-Z0-9_]+)':", block_content)
        langs[lang_code] = set(keys)

    en_keys = langs.get('en', set())
    print(f"Total keys in 'en': {len(en_keys)}")

    for lang, keys in langs.items():
        if lang == 'en':
            continue
        missing = en_keys - keys
        extra = keys - en_keys
        print(f"\nAudit for '{lang}':")
        print(f"  Total keys: {len(keys)}")
        print(f"  Missing keys: {len(missing)}")
        if missing:
            print(f"  Sample missing keys: {list(missing)[:10]}")
        print(f"  Extra keys (not in 'en'): {len(extra)}")
        if extra:
            print(f"  Sample extra keys: {list(extra)[:10]}")

if __name__ == "__main__":
    audit_translations()
