import json
import sys

def check_duplicates(pairs):
    d = {}
    for k, v in pairs:
        if k in d:
            print(f"Duplicate key found: {k}")
        d[k] = v
    return d

try:
    with open('workmate/assets/translations/vi.json', 'r', encoding='utf-8') as f:
        json.load(f, object_pairs_hook=check_duplicates)
    with open('workmate/assets/translations/en.json', 'r', encoding='utf-8') as f:
        json.load(f, object_pairs_hook=check_duplicates)
except Exception as e:
    print("Error:", e)
