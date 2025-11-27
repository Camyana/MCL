import requests
import re
import os
from bs4 import BeautifulSoup
import json
import sys

def get_mount_info(item_id):
    url = f"https://www.wowhead.com/item={item_id}"
    resp = requests.get(url, headers={"User-Agent": "Mozilla/5.0"})
    soup = BeautifulSoup(resp.text, "html.parser")
    # Get name
    name_tag = soup.find("h1", class_="heading-size-1")
    name = name_tag.text.strip() if name_tag else f"Item {item_id}"
    # Get icon
    icon_tag = soup.find("meta", property="og:image")
    icon_url = icon_tag["content"] if icon_tag else ""
    return {"id": item_id, "name": name, "icon": icon_url, "link": url}

def extract_mount_ids_from_data_lua(lua_path):
    with open(lua_path, 'r', encoding='utf-8') as f:
        lua = f.read()
    # Find all mounts = { ... } tables
    mounts_tables = re.findall(r'mounts\s*=\s*\{([^}]*)\}', lua, re.DOTALL)
    ids = set()
    for table in mounts_tables:
        for match in re.finditer(r'(?<![\w\"])(\d{4,6})(?![\w\"])', table):
            ids.add(int(match.group(1)))
    return ids

def extract_sections_and_categories(lua_path):
    with open(lua_path, 'r', encoding='utf-8') as f:
        lua = f.read()
    # Helper to extract a full {...} block given the start index of the opening brace
    def extract_brace_block(s, start):
        depth = 0
        for i in range(start, len(s)):
            if s[i] == '{':
                depth += 1
            elif s[i] == '}':
                depth -= 1
                if depth == 0:
                    return s[start:i+1]
        return ''
    # Build a mapping of mountList index -> list of category display names
    mountlist_map = {}
    mountlist_pattern = re.compile(r'MCLcore\.mountList\[(\d+)\]\s*=\s*\{', re.DOTALL)
    for m in mountlist_pattern.finditer(lua):
        idx = m.group(1)
        mountlist_start = m.end()
        # Find categories = { ... } inside this mountList
        cat_match = re.search(r'categories\s*=\s*{', lua[mountlist_start:])
        if cat_match:
            cat_start = mountlist_start + cat_match.end() - 1  # index of the opening brace
            cat_block = extract_brace_block(lua, cat_start)
            cats = []
            for cat in re.finditer(r'name\s*=\s*"([^"]+)"', cat_block):
                cats.append(cat.group(1))
            mountlist_map[idx] = cats
    # Now, parse all sectionNames and map to their categories
    section_pattern = re.compile(r'MCLcore\.sectionNames\[(\d+)\]\s*=\s*\{[^}]*?name\s*=\s*"([^"]+)"[\s\S]*?mounts\s*=\s*MCLcore\.mountList\[(\d+)\]', re.MULTILINE)
    section_categories = {}
    for match in section_pattern.finditer(lua):
        idx, display_name, mountlist_idx = match.groups()
        cats = mountlist_map.get(mountlist_idx, [])
        section_categories[display_name] = cats
    return section_categories

def get_mounts_info_from_listpage(missing_ids, list_url):
    resp = requests.get(list_url, headers={"User-Agent": "Mozilla/5.0"})
    soup = BeautifulSoup(resp.text, "html.parser")
    mounts = []
    for tr in soup.find_all("tr", class_="listview-row"):
        a = tr.find("a", href=True)
        if not a or not a["href"].startswith("/item="):
            continue
        m = re.search(r'/item=(\d+)', a["href"])
        if not m:
            continue
        item_id = int(m.group(1))
        if item_id not in missing_ids:
            continue
        # Get icon
        icon_div = tr.find("div", class_="iconmedium")
        icon_url = ""
        if icon_div:
            ins = icon_div.find("ins")
            if ins and "background-image" in ins.attrs.get("style", ""):
                style = ins["style"]
                m_icon = re.search(r'url\(([^)]+)\)', style)
                if m_icon:
                    icon_url = m_icon.group(1).replace('&quot;', '')
        # Get name
        name = a.text.strip()
        # Get link
        link = "https://www.wowhead.com" + a["href"]
        mounts.append({"id": item_id, "name": name, "icon": icon_url, "link": link})
    # Some missing_ids may not be found (e.g. not on this page), so add fallback for those
    found_ids = {m["id"] for m in mounts}
    for item_id in missing_ids:
        if item_id not in found_ids:
            mounts.append({"id": item_id, "name": f"Item {item_id}", "icon": "", "link": f"https://www.wowhead.com/item={item_id}"})
    return mounts

def load_mounts_info_json(json_path):
    with open(json_path, "r", encoding="utf-8") as f:
        return json.load(f)

def main():
    from mount_report import fetch_mount_item_ids_selenium, extract_mount_ids_from_data_lua
    ptr_json = "mounts_ptr.json"
    live_json = "mounts_live.json"
    use_ptr = len(sys.argv) > 1 and sys.argv[1].lower() == "ptr"
    if use_ptr:
        json_path = ptr_json
        label = "PTR"
    else:
        json_path = live_json
        label = "LIVE"
    # Load all mount info from JSON
    all_mounts = load_mounts_info_json(json_path)
    all_mounts_by_id = {m["id"]: m for m in all_mounts}
    # Get missing IDs
    lua_mount_ids = extract_mount_ids_from_data_lua('data.lua')
    missing_ids = sorted(set(all_mounts_by_id.keys()) - lua_mount_ids)
    mounts = [all_mounts_by_id[i] for i in missing_ids if i in all_mounts_by_id]
    
    # Filter out placeholder mounts (those starting with [PH])
    mounts = [m for m in mounts if not m['name'].startswith('[PH]')]
    
    mounts = sorted(mounts, key=lambda m: m['name'].lower())
    section_cats = extract_sections_and_categories('data.lua')
    # Find the section before 'Horde' to use as the default expansion section
    section_names = list(section_cats.keys())
    if 'Horde' in section_names:
        horde_idx = section_names.index('Horde')
        default_section = section_names[horde_idx - 1] if horde_idx > 0 else section_names[0]
    else:
        default_section = section_names[-1] if section_names else ''
    # Write HTML with Tailwind CSS (dark theme)
    with open('missing_mounts.html', 'w', encoding='utf-8') as f:
        f.write('<!DOCTYPE html>\n<html lang="en">\n<head>\n')
        f.write('<meta charset="UTF-8">\n<meta name="viewport" content="width=device-width, initial-scale=1.0">\n')
        f.write(f'<title>Missing Mounts ({label})</title>\n')
        f.write('<script src="https://cdn.tailwindcss.com"></script>\n')
        f.write('<script>tailwind.config = { darkMode: "class" }</script>\n')
        f.write('</head>\n<body class="dark bg-gray-900 min-h-screen text-gray-200">\n')
        f.write('<div class="max-w-3xl mx-auto p-6">\n')
        f.write(f'<h1 class="text-3xl font-bold mb-8 text-center text-blue-400">Missing Mounts ({label})</h1>\n')
        f.write('<form class="space-y-6" id="mounts-form">\n')
        for idx, m in enumerate(mounts):
            icon_url = m['icon'].strip('"') if m['icon'] else ''
            f.write(f'<div class="mount-card flex items-center bg-gray-800 rounded-lg shadow p-4 gap-4 border border-gray-700 transition-opacity" id="mount-card-{idx}">')
            if icon_url:
                f.write(f'<img src="{icon_url}" class="w-12 h-12 rounded border border-gray-700 bg-gray-900" alt="icon">')
            f.write('<div class="flex-1">')
            f.write(f'<a href="{m["link"]}" target="_blank" class="text-lg font-semibold text-blue-300 hover:underline">{m["name"]}</a> ')
            f.write(f'<span class="text-gray-400 text-sm">(ID: {m["id"]})</span><br>')
            # Section dropdown, default to last expansion
            f.write('<label class="block mt-2 text-sm font-medium text-gray-300">Section: ')
            f.write(f'<select name="section-{idx}" id="section-{idx}" class="ml-2 border border-gray-700 rounded px-2 py-1 bg-gray-900 text-gray-200">')
            for section in section_cats:
                selected = ' selected' if section == default_section else ''
                f.write(f'<option value="{section}"{selected}>{section}</option>')
            f.write('</select></label> ')
            # Category dropdown, default to blank
            f.write('<label class="block mt-2 text-sm font-medium text-gray-300">Category: ')
            f.write(f'<select name="category-{idx}" id="category-{idx}" class="ml-2 border border-gray-700 rounded px-2 py-1 bg-gray-900 text-gray-200">')
            f.write('<option value="">-- Select Category --</option>')
            f.write('</select></label>')
            f.write('</div>')
            # Exclude checkbox
            f.write(f'<div class="ml-4 flex flex-col items-center"><label class="text-xs text-gray-400"><input type="checkbox" class="exclude-checkbox" data-card="mount-card-{idx}"> Exclude</label></div>')
            f.write(f'<input type="hidden" name="mount_id" value="{m["id"]}">')
            f.write('</div>\n')
        f.write('</form>\n')
        # Save button
        f.write('<div class="flex justify-end mt-8"><button id="save-btn" type="button" class="px-6 py-2 rounded bg-blue-600 hover:bg-blue-700 text-white font-bold">Save</button></div>\n')
        f.write('<script>')
        f.write('const sectionCats = ' + json.dumps(section_cats) + ';\n')
        f.write('document.querySelectorAll("select[id^=section-]").forEach((sel) => {\n'
                '  const idx = sel.id.split("-")[1];\n'
                '  sel.addEventListener("change", function() {\n'
                '    const catSel = document.getElementById("category-" + idx);\n'
                '    catSel.innerHTML = `<option value=\"\">-- Select Category --</option>` + sectionCats[this.value].map(c => `<option value=\"${c}\">${c}</option>`).join("");\n'
                '  });\n'
                '  sel.dispatchEvent(new Event("change"));\n'
                '});\n')
        # Exclude/gray out logic
        f.write('document.querySelectorAll(".exclude-checkbox").forEach(cb => {\n'
                '  cb.addEventListener("change", function() {\n'
                '    const card = document.getElementById(this.dataset.card);\n'
                '    if (this.checked) {\n'
                '      card.classList.add("opacity-40");\n'
                '    } else {\n'
                '      card.classList.remove("opacity-40");\n'
                '    }\n'
                '  });\n'
                '});\n')
        # Save button logic
        f.write('document.getElementById("save-btn").addEventListener("click", function() {\n'
                '  const cards = document.querySelectorAll(".mount-card");\n'
                '  const data = Array.from(cards).map((card, idx) => {\n'
                '    const id = card.querySelector("input[name=mount_id]").value;\n'
                '    const section = document.getElementById("section-" + idx).value;\n'
                '    const category = document.getElementById("category-" + idx).value;\n'
                '    const exclude = card.querySelector(".exclude-checkbox").checked;\n'
                '    return {id, section, category, exclude};\n'
                '  });\n'
                '  const blob = new Blob([JSON.stringify(data, null, 2)], {type: "application/json"});\n'
                '  const url = URL.createObjectURL(blob);\n'
                '  const a = document.createElement("a");\n'
                '  a.href = url;\n'
                '  a.download = "mounts_to_add.json";\n'
                '  document.body.appendChild(a);\n'
                '  a.click();\n'
                '  document.body.removeChild(a);\n'
                '  URL.revokeObjectURL(url);\n'
                '});\n')
        f.write('</script>\n')
        f.write('</div>\n</body>\n</html>')

if __name__ == "__main__":
    main()
