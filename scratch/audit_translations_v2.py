
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
    # Using a more robust regex to find 'xx': { ... }
    lang_blocks = re.findall(r"  '([a-z]{2})': \{(.*?)\n  \},", translations_body, re.DOTALL)
    
    langs = {}
    for lang_code, block_content in lang_blocks:
        # Extract keys and values
        # Matches: 'key': 'value',
        kv_pairs = re.findall(r"    '([a-zA-Z0-9_]+)': '(.*?)',", block_content)
        langs[lang_code] = {k: v for k, v in kv_pairs}

    en_dict = langs.get('en', {})
    print(f"Total keys in 'en': {len(en_dict)}")

    for lang, kv in langs.items():
        if lang == 'en':
            continue
        
        all_keys = set(en_dict.keys()) | set(kv.keys())
        missing = set(en_dict.keys()) - set(kv.keys())
        extra = set(kv.keys()) - set(en_dict.keys())
        
        # Check for English fallbacks (same value as English)
        fallbacks = []
        for k in kv:
            if k in en_dict and kv[k] == en_dict[k] and len(kv[k]) > 0:
                # Some keys might be intended to be the same (e.g. brand name "Tremble")
                # But if most are the same, it's a problem.
                if k not in ['app_name', 'tremble', 'brand_name']: 
                    fallbacks.append(k)

        print(f"\nAudit for '{lang}':")
        print(f"  Total keys: {len(kv)}")
        print(f"  Missing keys (compared to EN): {len(missing)}")
        print(f"  Extra keys (not in EN): {len(extra)}")
        print(f"  English fallback values: {len(fallbacks)}")
        if fallbacks:
             print(f"  Sample fallbacks: {fallbacks[:5]}")

if __name__ == "__main__":
    audit_translations()
