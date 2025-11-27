from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
from bs4 import BeautifulSoup
from typing import Optional
import re
import time
import ast
import sys
import json


def _build_webdriver(headless: bool = True, driver_path: Optional[str] = None) -> webdriver.Chrome:
    """Return a Chrome webdriver, auto-installing/updating ChromeDriver if needed."""

    options = Options()
    if headless:
        # Use the modern headless mode to avoid deprecation warnings on Chrome 109+
        options.add_argument('--headless=new')
    options.add_argument('--disable-gpu')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')

    executable_path = driver_path or ChromeDriverManager().install()
    service = Service(executable_path=executable_path)
    return webdriver.Chrome(service=service, options=options)

def fetch_mount_item_ids_selenium(url, driver_path: Optional[str] = None):
    driver = _build_webdriver(driver_path=driver_path)
    driver.get(url)

    all_item_ids = set()
    wait = WebDriverWait(driver, 20)
    
    # Handle cookie consent popup if it appears
    try:
        cookie_button = wait.until(EC.element_to_be_clickable((By.ID, "onetrust-accept-btn-handler")))
        cookie_button.click()
        print("Clicked cookie consent button")
        time.sleep(1)
    except:
        print("No cookie consent popup found or already handled")
        pass

    while True:
        # Wait for the table to load
        wait.until(EC.presence_of_element_located((By.CLASS_NAME, 'listview-mode-default')))
        soup = BeautifulSoup(driver.page_source, "html.parser")
        table = soup.find('table', class_='listview-mode-default')
        if not table:
            print("No table found, aborting!")
            break

        # Grab item IDs from this page
        for link in table.find_all('a', href=True):
            m = re.search(r'/item=(\d+)', link['href'])
            if m:
                all_item_ids.add(int(m.group(1)))

        # Try to go to next page
        try:
            next_button = wait.until(EC.element_to_be_clickable((By.XPATH, "//div[@class='listview-nav']//a[contains(text(), 'Next') and not(contains(@style, 'display: none'))]")))
            driver.execute_script("arguments[0].click();", next_button)
            print("Clicked next page button")
            time.sleep(2)  # Wait for JS to reload
        except:
            print("No more pages or next button not found")
            break

    driver.quit()
    return all_item_ids

def extract_mount_ids_from_data_lua(lua_path):
    with open(lua_path, 'r', encoding='utf-8') as f:
        lua = f.read()
    # Find all mounts = { ... } tables
    mounts_tables = re.findall(r'mounts\s*=\s*\{([^}]*)\}', lua, re.DOTALL)
    ids = set()
    for table in mounts_tables:
        # Find all numbers in the table (ignore quoted strings and m1234 style)
        for match in re.finditer(r'(?<![\w\"])(\d{4,6})(?![\w\"])', table):
            ids.add(int(match.group(1)))
    return ids

def fetch_mounts_info_selenium(url, driver_path: Optional[str] = None):
    driver = _build_webdriver(driver_path=driver_path)
    driver.get(url)

    all_mounts = []
    wait = WebDriverWait(driver, 20)
    
    # Handle cookie consent popup if it appears
    try:
        cookie_button = wait.until(EC.element_to_be_clickable((By.ID, "onetrust-accept-btn-handler")))
        cookie_button.click()
        print("Clicked cookie consent button")
        time.sleep(1)
    except:
        print("No cookie consent popup found or already handled")
        pass

    while True:
        wait.until(EC.presence_of_element_located((By.CLASS_NAME, 'listview-mode-default')))
        soup = BeautifulSoup(driver.page_source, "html.parser")
        table = soup.find('table', class_='listview-mode-default')
        if not table:
            print("No table found, aborting!")
            break
        for tr in table.find_all("tr", class_="listview-row"):
            a_tags = [a for a in tr.find_all("a", href=True) if "item=" in a["href"]]
            if not a_tags:
                continue
            a_icon = a_tags[0]
            m = re.search(r'item=(\d+)', a_icon["href"])
            if not m:
                continue
            item_id = int(m.group(1))
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
            # Get name from the second <a> if available, else fallback to first
            if len(a_tags) > 1 and a_tags[1].text.strip():
                name = a_tags[1].text.strip()
                href = a_tags[1]["href"]
            else:
                name = a_icon.text.strip()
                href = a_icon["href"]
            if href.startswith("/"):
                link = "https://www.wowhead.com" + href
            else:
                link = href
            all_mounts.append({"id": item_id, "name": name, "icon": icon_url, "link": link})
        # Try to go to next page
        try:
            next_button = wait.until(EC.element_to_be_clickable((By.XPATH, "//div[@class='listview-nav']//a[contains(text(), 'Next') and not(contains(@style, 'display: none'))]")))
            driver.execute_script("arguments[0].click();", next_button)
            print("Clicked next page button")
            time.sleep(2)
        except:
            print("No more pages or next button not found")
            break
    driver.quit()
    return all_mounts

# Usage
if __name__ == "__main__":
    use_ptr = len(sys.argv) > 1 and sys.argv[1].lower() == "ptr"
    if use_ptr:
        url = "https://www.wowhead.com/ptr-2/items/miscellaneous/mounts?filter=82;2;110205"
        json_out = "mounts_ptr.json"
        print("Using PTR URL")
    else:
        # url = "https://www.wowhead.com/items/miscellaneous/mounts?filter=82;2;110107" # 11.1.7
        url = "https://www.wowhead.com/items/miscellaneous/mounts?filter=82;2;110205" # 1.1.2
        json_out = "mounts_live.json"
        print("Using LIVE URL")
    mounts_info = fetch_mounts_info_selenium(url)
    with open(json_out, "w", encoding="utf-8") as f:
        json.dump(mounts_info, f, ensure_ascii=False, indent=2)
    print(f"Wrote {len(mounts_info)} mounts to {json_out}")
