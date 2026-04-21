#!/bin/bash
# Salla CDN Uploader
# Usage: ./salla-upload.sh <image_path> [token]
#        ./salla-upload.sh image1.webp image2.jpg [token]
#
# Token: grab from Chrome DevTools (Network tab) → any request → Authorization header
# You can also set it as env var: export SALLA_TOKEN="v4.public.xxx"

UPLOAD_URL="https://api.salla.dev/admin/v2/uploader/files/homepage"

# Collect files and token
FILES=()
TOKEN="$SALLA_TOKEN"

for arg in "$@"; do
  if [[ -f "$arg" ]]; then
    FILES+=("$arg")
  else
    TOKEN="$arg"
  fi
done

if [ ${#FILES[@]} -eq 0 ]; then
  echo "Usage: ./salla-upload.sh <image_path...> [token]"
  echo "  or:  SALLA_TOKEN='v4.public.xxx' ./salla-upload.sh <image_path...>"
  exit 1
fi

if [ -z "$TOKEN" ]; then
  echo "Error: No token provided. Pass as last arg or set SALLA_TOKEN env var."
  exit 1
fi

# Detect MIME type
get_mime() {
  case "${1##*.}" in
    jpg|jpeg) echo "image/jpeg" ;;
    png)      echo "image/png" ;;
    gif)      echo "image/gif" ;;
    webp)     echo "image/webp" ;;
    avif)     echo "image/avif" ;;
    pdf)      echo "application/pdf" ;;
    csv)      echo "text/csv" ;;
    *)        echo "application/octet-stream" ;;
  esac
}

# Upload and collect URLs
URLS=()

for IMAGE_PATH in "${FILES[@]}"; do
  FILENAME=$(basename "$IMAGE_PATH")
  MIME=$(get_mime "$FILENAME")

  echo "Uploading: $FILENAME ..."

  RESPONSE=$(curl -s --noproxy '*' -X POST "$UPLOAD_URL" \
    -H "accept: */*" \
    -H "authorization: Bearer $TOKEN" \
    -F "file=@${IMAGE_PATH};type=${MIME}" \
    -F "alt=" \
    -F "default=0" \
    -F "sort=1")

  # Extract URL from response
  URL=$(echo "$RESPONSE" | grep -oP '"(url|link)"\s*:\s*"\K[^"]*' | head -1)

  if [ -n "$URL" ]; then
    echo "✅ $URL"
    echo ""
    URLS+=("$URL")
  else
    echo "❌ Upload failed:"
    echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
    echo ""
  fi
done

# Copy to clipboard
if [ ${#URLS[@]} -eq 1 ]; then
  CLIP="${URLS[0]}"
elif [ ${#URLS[@]} -gt 1 ]; then
  echo "────────────────────────────────────────"
  echo "All URLs:"
  for u in "${URLS[@]}"; do
    echo "  $u"
  done
  CLIP=$(printf '%s\n' "${URLS[@]}")
fi

if [ -n "$CLIP" ]; then
  if command -v pbcopy &>/dev/null; then
    echo -n "$CLIP" | pbcopy
    echo "(Copied to clipboard)"
  elif command -v xclip &>/dev/null; then
    echo -n "$CLIP" | xclip -selection clipboard
    echo "(Copied to clipboard)"
  elif command -v clip.exe &>/dev/null; then
    echo -n "$CLIP" | clip.exe
    echo "(Copied to clipboard)"
  fi
fi
