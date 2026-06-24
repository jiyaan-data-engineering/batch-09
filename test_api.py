"""
Test script to debug API connection issues
"""
import requests

def test_api_connection():
    url = 'https://cricbuzz-cricket.p.rapidapi.com/stats/v1/rankings/batsmen'
    headers = {
        "X-RapidAPI-Key": "Replace with your RapidAPI key",
        "X-RapidAPI-Host": "cricbuzz-cricket.p.rapidapi.com"
    }
    params = {'formatType': 'odi'}

    print("=" * 60)
    print("🔍 API Connection Test")
    print("=" * 60)
    print()

    # Check 1: Validate API key
    print("1️⃣  Checking API Key...")
    api_key = headers["X-RapidAPI-Key"]
    if api_key == "Replace with your RapidAPI key":
        print("   ❌ API Key is PLACEHOLDER")
        print("   ➡️  You must replace it with actual key from RapidAPI")
        print()
        return False
    else:
        print(f"   ✅ API Key found: {api_key[:10]}...{api_key[-5:]}")
        print()

    # Check 2: Test connectivity
    print("2️⃣  Testing API Endpoint...")
    print(f"   URL: {url}")
    print(f"   Host: {headers['X-RapidAPI-Host']}")
    print()

    try:
        response = requests.get(url, headers=headers, params=params, timeout=5)

        print(f"3️⃣  Response Status: {response.status_code}")
        print()

        if response.status_code == 200:
            print("   ✅ SUCCESS! API returned data")
            data = response.json()
            print(f"   📊 Data received: {len(data.get('rank', []))} rankings")
            return True

        elif response.status_code == 401:
            print("   ❌ UNAUTHORIZED (401)")
            print("   Reason: API key is invalid or missing")
            print("   Solution: Get a new key from https://rapidapi.com/")
            return False

        elif response.status_code == 403:
            print("   ❌ FORBIDDEN (403)")
            print("   Possible reasons:")
            print("      • API key is wrong or expired")
            print("      • API subscription is not active")
            print("      • Free tier quota exceeded")
            print("   Solution: Check RapidAPI dashboard")
            return False

        elif response.status_code == 429:
            print("   ❌ TOO MANY REQUESTS (429)")
            print("   Reason: Rate limit exceeded")
            print("   Solution: Wait and try again later")
            return False

        else:
            print(f"   ❌ ERROR: {response.status_code}")
            print(f"   Response: {response.text[:200]}")
            return False

    except requests.exceptions.ConnectionError:
        print("   ❌ CONNECTION ERROR")
        print("   Reason: Cannot reach API server")
        print("   Solution: Check internet connection")
        return False

    except Exception as e:
        print(f"   ❌ ERROR: {str(e)}")
        return False

if __name__ == "__main__":
    success = test_api_connection()
    print()
    print("=" * 60)
    if success:
        print("✅ API is working! You can run extract_data.py")
    else:
        print("⚠️  API connection failed. See details above.")
    print("=" * 60)
