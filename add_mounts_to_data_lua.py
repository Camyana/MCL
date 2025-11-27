import json
import re

MOUNTS_JSON = 'mounts_to_add.json'
DATA_LUA = 'data.lua'

with open(MOUNTS_JSON, encoding='utf-8') as f:
    mounts = json.load(f)

with open(DATA_LUA, encoding='utf-8') as f:
    lua = f.read()

def extract_brace_block(s, start):
    depth = 0
    for i in range(start, len(s)):
        if s[i] == '{':
            depth += 1
            if depth == 1:
                block_start = i
        elif s[i] == '}':
            depth -= 1
            if depth == 0:
                return s[start:i+1]
    return ''

def find_category_block(section_block, category_display_name):
    # Find all category blocks in the section_block using brace counting
    cat_key_pattern = re.compile(r'(\w+)\s*=\s*{')
    found_any = False
    for m in cat_key_pattern.finditer(section_block):
        start = m.start()
        # Find the full block for this category
        depth = 0
        for i in range(start, len(section_block)):
            if section_block[i] == '{':
                depth += 1
                if depth == 1:
                    block_start = i
            elif section_block[i] == '}':
                depth -= 1
                if depth == 0:
                    block_end = i
                    block = section_block[start:block_end+1]
                    # Print the category block being checked
                    print(f"Checking category block at {start}-{block_end} for display name '{category_display_name}'...")
                    name_match = re.search(r'name\s*=\s*"' + re.escape(category_display_name) + r'"', block)
                    if name_match:
                        print(f"Matched category '{category_display_name}'!")
                        return start, block_end+1, block
                    found_any = True
                    break
    if not found_any:
        print("No category blocks found in this section!")
    return None, None, None

# Build a mapping: (section, category) -> list of mount ids to add
add_map = {}
for m in mounts:
    if m.get('exclude') or not m.get('category') or not m.get('section'):
        continue
    key = (m['section'], m['category'])
    add_map.setdefault(key, []).append(int(m['id']))

for (section, category), ids in add_map.items():
    # Find the section block
    section_pattern = rf'name\s*=\s*"{re.escape(section)}"[\s\S]*?categories\s*=\s*{{'
    section_match = re.search(section_pattern, lua)
    if not section_match:
        print(f"Section '{section}' not found!")
        continue
    cat_block_start = section_match.end() - 1  # index of the opening brace
    section_block = extract_brace_block(lua, cat_block_start)
    print(f"\nSection '{section}' found. Looking for categories...")
    # Print all category display names found in this section
    for catname in re.findall(r'name\s*=\s*"([^"]+)"', section_block):
        print(f"  Found category display name: {catname}")
    # Find the category block by display name using brace counting
    cat_start, cat_end, cat_block = find_category_block(section_block, category)
    if cat_block is None:
        print(f"Category '{category}' not found in section '{section}'!")
        continue
    # Find mounts = { ... } in cat_block
    mounts_match = re.search(r'mounts\s*=\s*{([\s\S]*?)}', cat_block)
    if not mounts_match:
        print(f"No mounts list found in {section} -> {category}!")
        continue
    mounts_list = mounts_match.group(1)
    # Prepare new ids (skip if already present)
    existing_ids = set(int(x) for x in re.findall(r'\b(\d{4,6})\b', mounts_list))
    new_ids = [i for i in ids if i not in existing_ids]
    if not new_ids:
        continue
    # Insert before the closing }
    insert_str = ', ' + ', '.join(str(i) for i in new_ids)
    # Replace the mounts list in cat_block
    new_cat_block = cat_block[:mounts_match.end(1)] + insert_str + cat_block[mounts_match.end(1):]
    # Replace the category block in section_block
    new_section_block = section_block[:cat_start] + new_cat_block + section_block[cat_end:]
    # Replace the section block in lua
    lua = lua.replace(section_block, new_section_block, 1)
    print(f"Added {new_ids} to {section} -> {category}")

with open(DATA_LUA, 'w', encoding='utf-8') as f:
    f.write(lua)

print("Done updating data.lua!")
