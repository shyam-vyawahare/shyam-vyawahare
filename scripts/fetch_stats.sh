#!/usr/bin/env bash
set -euo pipefail

USER="${GH_USER:-shyam-vyawahare}"
OUTDIR="assets"
mkdir -p "$OUTDIR"

# common curl options
CURL_OPTS="-fsSL --retry 3 --retry-delay 2 -A 'github-actions-fetch/1.0'"

# helper: try URLs, validate HTTP 200 and file size > 1500 bytes
fetch_and_validate() {
  local -n urls=$1
  local out="$2"
  for u in "${urls[@]}"; do
    echo "-> trying: $u"
    # download to tmp
    tmp="$(mktemp)"
    if curl $CURL_OPTS -o "$tmp" "$u"; then
      size=$(wc -c < "$tmp" || echo 0)
      # require reasonable size (avoid HTML error pages)
      if [[ "$size" -gt 1500 ]]; then
        mv "$tmp" "$out"
        echo "Saved $out (size: $size) from $u"
        return 0
      else
        echo "Downloaded but file too small ($size bytes) — skipping"
      fi
    else
      echo "curl failed for $u"
    fi
    rm -f "$tmp"
  done
  echo "All mirrors failed for $out" >&2
  return 1
}

# 1) github-stats card
stats_urls=(
  "https://github-readme-stats.vercel.app/api?username=${USER}&show_icons=true&theme=react&count_private=true"
  "https://github-readme-stats-git-masterrstaa-rickstaa.vercel.app/api?username=${USER}&show_icons=true&theme=react&count_private=true"
  "https://gh-readme-stats.herokuapp.com/api?username=${USER}&show_icons=true&theme=react"
)
fetch_and_validate stats_urls "${OUTDIR}/github-stats.png" || echo "github-stats: failed"

# 2) streak card
streak_urls=(
  "https://github-readme-streak-stats.herokuapp.com/?user=${USER}&theme=react"
  "https://streak-stats.demolab.com?user=${USER}&theme=react"
  "https://streak-readme-stats.vercel.app/?user=${USER}&theme=react"
)
fetch_and_validate streak_urls "${OUTDIR}/streak-stats.png" || echo "streak-stats: failed"

# 3) top-langs card
toplang_urls=(
  "https://github-readme-stats.vercel.app/api/top-langs/?username=${USER}&layout=compact&theme=react"
  "https://github-readme-stats-git-masterrstaa-rickstaa.vercel.app/api/top-langs/?username=${USER}&layout=compact&theme=react"
)
fetch_and_validate toplang_urls "${OUTDIR}/top-langs.png" || echo "top-langs: failed"

echo "Done. Listing assets:"
ls -lh "$OUTDIR" || true
