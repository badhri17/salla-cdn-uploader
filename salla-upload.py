"""
Salla CDN Uploader
Upload images to Salla's CDN and get the link back.

Usage:
  python salla-upload.py image.webp
  python salla-upload.py image.webp --token "v4.public.xxx"
  python salla-upload.py *.webp  (batch upload)

Token: Grab from Chrome DevTools → Network tab → any Salla request → Authorization header
       Or set env var: SALLA_TOKEN=v4.public.xxx
"""

import requests
import sys
import os
import argparse
import subprocess
import platform
import mimetypes

UPLOAD_URL = "https://api.salla.dev/admin/v2/uploader/files/homepage"


def copy_to_clipboard(text):
    try:
        if platform.system() == "Windows":
            subprocess.run("clip", input=text.encode(), check=True)
        elif platform.system() == "Darwin":
            subprocess.run("pbcopy", input=text.encode(), check=True)
        else:
            subprocess.run(["xclip", "-selection", "clipboard"], input=text.encode(), check=True)
        return True
    except Exception:
        return False


def upload(filepath, token):
    filename = os.path.basename(filepath)

    headers = {
        "accept": "*/*",
        "authorization": f"Bearer {token}",
    }

    with open(filepath, "rb") as f:
        mime = mimetypes.guess_type(filepath)[0] or "image/jpeg"
        files = {"file": (filename, f, mime)}
        data = {"alt": "", "default": "0", "sort": "1"}
        resp = requests.post(UPLOAD_URL, headers=headers, files=files, data=data, proxies={"http": None, "https": None})

    try:
        body = resp.json()
    except Exception:
        print(f"❌ Non-JSON response ({resp.status_code}): {resp.text[:300]}")
        return None

    if resp.status_code == 200 and body.get("success"):
        # The URL could be nested differently depending on the endpoint version
        url = body.get("data", {}).get("url") or body.get("data", {}).get("link")
        if not url:
            # fallback: try to find any URL-like value in data
            data_obj = body.get("data", {})
            if isinstance(data_obj, dict):
                for v in data_obj.values():
                    if isinstance(v, str) and v.startswith("http"):
                        url = v
                        break
        return url
    else:
        print(f"❌ Upload failed ({resp.status_code})")
        print(body)
        return None


def main():
    parser = argparse.ArgumentParser(description="Upload images to Salla CDN")
    parser.add_argument("files", nargs="+", help="Image file(s) to upload")
    parser.add_argument("--token", "-t", default=os.environ.get("SALLA_TOKEN", ""),
                        help="Bearer token (or set SALLA_TOKEN env var)")
    args = parser.parse_args()

    if not args.token:
        print("Error: No token. Use --token or set SALLA_TOKEN env var.")
        sys.exit(1)

    urls = []
    for filepath in args.files:
        if not os.path.isfile(filepath):
            print(f"⚠️  Skipping (not found): {filepath}")
            continue

        print(f"Uploading: {os.path.basename(filepath)} ...")
        url = upload(filepath, args.token)
        if url:
            print(f"✅ {url}\n")
            urls.append(url)

    if len(urls) == 1:
        if copy_to_clipboard(urls[0]):
            print("(Copied to clipboard)")
    elif len(urls) > 1:
        print("─" * 40)
        print("All URLs:")
        for u in urls:
            print(f"  {u}")
        joined = "\n".join(urls)
        if copy_to_clipboard(joined):
            print("\n(All copied to clipboard)")


if __name__ == "__main__":
    main()
