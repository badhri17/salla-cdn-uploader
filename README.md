# Salla CDN Uploader

A lightweight CLI tool to upload images to Salla's CDN and get back the hosted URL — no dashboard needed.

Available in both **Python** and **Bash**.

## Why?

Salla doesn't expose a public CDN upload endpoint for developers. This tool uses the same internal API the dashboard uses, so you can upload assets from your terminal and get a CDN link instantly — useful when injecting custom JS/CSS components into Salla storefronts.

## Setup

### Python (Windows / Mac / Linux)

```bash
pip install requests
```

### Bash (Mac / Linux / WSL)

```bash
chmod +x salla-upload.sh
```

## Getting Your Token

1. Open your Salla dashboard in Chrome
2. Open DevTools → **Network** tab
3. Do any action (e.g. navigate a page)
4. Click any request to `api.salla.dev`
5. Copy the `Authorization: Bearer v4.public.xxx...` value

The token is valid for ~2 weeks.

## Usage

### Python

```bash
# Single file
python salla-upload.py image.webp --token "v4.public.xxx"

# Batch upload
python salla-upload.py hero.webp logo.png banner.jpg --token "v4.public.xxx"

# Using env var (so you don't paste the token every time)
export SALLA_TOKEN="v4.public.xxx"
python salla-upload.py image.webp
```

### Bash

```bash
./salla-upload.sh image.webp "v4.public.xxx"

# Batch
./salla-upload.sh hero.webp logo.png "v4.public.xxx"

# Using env var
export SALLA_TOKEN="v4.public.xxx"
./salla-upload.sh image.webp
```

### Output

```
Uploading: hero.webp ...
✅ https://cdn.salla.sa/xxxxx/hero.webp

(Copied to clipboard)
```

The URL is automatically copied to your clipboard.

## Supported File Types

| Type | Extensions |
|------|-----------|
| Images | `.jpg`, `.jpeg`, `.png`, `.gif`, `.webp`, `.avif` |
| Documents | `.pdf`, `.doc`, `.docx`, `.xls`, `.xlsx`, `.pptx` |
| Other | `.csv`, `.txt`, `.mp3`, `.wav`, `.ogg` |

## Notes

- If you're behind a proxy (e.g. v2rayN / Clash), the Python version bypasses it automatically via `proxies={"http": None, "https": None}`. The Bash version uses `--noproxy '*'`.
- The `STORE_ID` and `THEME_ID` headers were removed as the token already encodes store context. If uploads fail on a different store, you may need to re-add them.

## License

MIT
