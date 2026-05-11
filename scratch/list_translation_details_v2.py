import re

def parse_translations(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Improved regex to find language blocks
    # It looks for 'langCode': { ... }
    lang_blocks = re.findall(r"'([a-z]{2})':\s*\{(.*?)\n\s*\},", content, re.DOTALL)
    
    translations = {}
    for lang, dict_content in lang_blocks:
        # Improved regex for key-value pairs to handle both single and double quotes
        # Handles: 'key': 'value', OR 'key': "value", OR 'key': '''value''',
        # Also handles multiline strings if needed
        kv_pairs = re.findall(r"^\s*'(.*?)':\s*['\"]+(.*?)['\"]+,", dict_content, re.MULTILINE | re.DOTALL)
        translations[lang] = {k.strip(): v.strip() for k, v in kv_pairs}
    
    return translations

def audit_lang(target_lang, en_dict, target_dict):
    en_keys = set(en_dict.keys())
    target_keys = set(target_dict.keys())
    
    missing = en_keys - target_keys
    extra = target_keys - en_keys
    
    fallbacks = []
    for k in (en_keys & target_keys):
        # We consider it a fallback if it matches English exactly AND it's not a short technical string
        if en_dict[k] == target_dict[k] and len(en_dict[k]) > 3:
            # Check if it's a known "brand" name that shouldn't be translated
            if k in ['iqos', 'vape', 'cm', 'ok', 'status', 'email', 'radar']:
                continue
            fallbacks.append(k)
            
    return missing, extra, fallbacks

translations = parse_translations('lib/src/core/translations.dart')
en_dict = translations.get('en', {})

if not en_dict:
    print("Error: Could not parse EN dictionary.")
    exit(1)

print(f"Total EN keys: {len(en_dict)}")

for lang in ['sl', 'hr', 'de', 'it', 'fr', 'sr', 'hu']:
    target_dict = translations.get(lang, {})
    if not target_dict:
        print(f"\n--- {lang.upper()} NOT FOUND or Parse Error ---")
        continue
        
    missing, extra, fallbacks = audit_lang(lang, en_dict, target_dict)
    
    print(f"\n--- {lang.upper()} Audit ---")
    print(f"Total keys: {len(target_dict)}")
    print(f"Missing: {len(missing)}")
    if missing:
        print(f"  Keys: {sorted(list(missing))}")
    
    print(f"Fallbacks: {len(fallbacks)}")
    if fallbacks:
        print(f"  Keys: {sorted(list(fallbacks))}")

    print(f"Extra (Not in EN): {len(extra)}")
    if extra:
        # Check if they are actually in EN but skipped by regex
        real_extra = []
        for e in extra:
            real_extra.append(e)
        print(f"  Keys: {sorted(real_extra)}")
