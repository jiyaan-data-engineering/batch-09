"""
Generate Architecture.png from HTML
Requires: pip install pillow playwright
"""
import asyncio
from pathlib import Path

async def html_to_png():
    try:
        from playwright.async_api import async_playwright
    except ImportError:
        print("❌ Playwright not installed. Run: pip install playwright")
        print("Then run: playwright install")
        return False

    html_file = Path(__file__).parent / "architecture.html"
    output_file = Path(__file__).parent / "Architecture.png"

    if not html_file.exists():
        print(f"❌ HTML file not found: {html_file}")
        return False

    try:
        async with async_playwright() as p:
            browser = await p.chromium.launch()
            page = await browser.new_page(viewport={"width": 1400, "height": 900})

            # Load the HTML file
            await page.goto(f"file://{html_file.absolute()}", wait_until="networkidle")

            # Wait for animations to finish
            await page.wait_for_timeout(2000)

            # Take screenshot
            await page.screenshot(path=str(output_file), full_page=True)
            await browser.close()

            print(f"✅ Architecture diagram created: {output_file}")
            return True
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    success = asyncio.run(html_to_png())
    exit(0 if success else 1)
