from camoufox.sync_api import Camoufox

with Camoufox(
    headless=False,
    os="linux",
) as browser:
    page = browser.new_page()
    page.goto(
        "https://bot.sannysoft.com/",
        wait_until="domcontentloaded",
    )

    print("User agent:", page.evaluate("navigator.userAgent"))
    page.wait_for_timeout(240_000)
