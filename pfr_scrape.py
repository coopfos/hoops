from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

from bs4 import BeautifulSoup, Comment
import pandas as pd

url = "https://www.pro-football-reference.com/boxscores/202509070atl.htm"
table_id = "home_snap_counts"  # use "vis_snap_counts" for away

# 1) Launch headless Chrome with a realistic UA
opts = Options()
opts.add_argument("--headless=new")
opts.add_argument("--no-sandbox")
opts.add_argument("--disable-gpu")
opts.add_argument("--disable-dev-shm-usage")
opts.add_argument("user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                  "AppleWebKit/537.36 (KHTML, like Gecko) "
                  "Chrome/126.0.0.0 Safari/537.36")

driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=opts)

try:
    # 2) Single navigation
    driver.get(url)

    # Optional: wait until the wrapper div for the hidden table is present
    WebDriverWait(driver, 15).until(
        EC.presence_of_element_located((By.CSS_SELECTOR, f"#all_{table_id}"))
    )

    html = driver.page_source
finally:
    driver.quit()

# 3) Parse commented table HTML and load into pandas
soup = BeautifulSoup(html, "html.parser")
container = soup.find(id=f"all_{table_id}")
if container is None:
    raise RuntimeError(f"Wrapper all_{table_id} not found")

comment = next((n for n in container.descendants if isinstance(n, Comment) and "<table" in n), None)
if comment is None:
    raise RuntimeError(f"Commented table '{table_id}' not found")

df = pd.read_html(str(comment))[0]
if isinstance(df.columns, pd.MultiIndex):
    df.columns = df.columns.get_level_values(-1)

pd.set_option("display.max_rows", None)
pd.set_option("display.max_columns", None)
print(df)