import re

def parse_translations(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Simple regex to find the language maps
    lang_matches = re.findall(r"'(en|sl|de|it|fr|hr|sr|hu)':\s*\{(.*?)\},", content, re.DOTALL)
    
    translations = {}
    for lang, dict_content in lang_matches:
        # Extract keys and values using regex
        kv_pairs = re.findall(r"'(.*?)':\s*'(.*?)',", dict_content)
        translations[lang] = {k: v for k, v in kv_pairs}
    
    return translations

def audit_lang(target_lang, en_dict, target_dict):
    en_keys = set(en_dict.keys())
    target_keys = set(target_dict.keys())
    
    missing = en_keys - target_keys
    extra = target_keys - en_keys
    
    fallbacks = []
    for k in (en_keys & target_keys):
        if en_dict[k] == target_dict[k] and len(en_dict[k]) > 3: # Avoid short strings like 'cm', 'ok'
            fallbacks.append(k)
            
    return missing, extra, fallbacks

translations = parse_translations('lib/src/core/translations.dart')
en_dict = translations.get('en', {})

for lang in ['sl', 'hr', 'de', 'it', 'fr', 'sr', 'hu']:
    target_dict = translations.get(lang, {})
    if not target_dict:
        print(f"\n--- {lang.upper()} NOT FOUND ---")
        continue
        
    missing, extra, fallbacks = audit_lang(lang, en_dict, target_dict)
    
    print(f"\n--- {lang.upper()} Audit ---")
    print(f"Missing: {len(missing)}")
    if missing:
        print(f"  Keys: {sorted(list(missing))}")
    
    print(f"Fallbacks: {len(fallbacks)}")
    if fallbacks:
        print(f"  Keys: {sorted(list(fallbacks))}")

    print(f"Extra: {len(extra)}")
    if extra:
        print(f"  Keys: {sorted(list(extra))}")
