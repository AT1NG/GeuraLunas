#!/usr/bin/env bash
# Render semua docs/diagrams/*.mmd menjadi PNG.
# Butuh Node.js dan Chrome/Chromium. Jika Chrome tidak ada di PATH, set:
#   PUPPETEER_EXECUTABLE_PATH="/path/ke/chrome"
set -euo pipefail
cd "$(dirname "$0")"
for f in *.mmd; do
  npx -y @mermaid-js/mermaid-cli@11.4.2 -i "$f" -o "${f%.mmd}.png" \
    -c mermaid.config.json -b white -s 2 -w 1200
done
