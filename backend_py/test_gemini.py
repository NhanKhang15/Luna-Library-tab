import requests
import os
from dotenv import load_dotenv

load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")
print(f"Testing API Key: {api_key[:10]}...{api_key[-5:] if api_key else ''}")

# Verify current config: v1beta + gemini-2.0-flash
url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={api_key}"

payload = {
    "contents": [{"parts": [{"text": "Hello, are you working?"}]}]
}

try:
    response = requests.post(url, json=payload, headers={"Content-Type": "application/json"})
    print(f"Status Code: {response.status_code}")
    if response.status_code == 200:
        print(f"Success! Response excerpt: {response.text[:100]}...")
    else:
        print(f"Error Response: {response.text}")
except Exception as e:
    print(f"Error: {e}")
