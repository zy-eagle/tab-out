#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXT_DIR="$SCRIPT_DIR/extension"
ICONS_DIR="$EXT_DIR/icons"
DIST_DIR="$SCRIPT_DIR/dist"
SVG_SRC="$ICONS_DIR/icon.svg"

# ── Prerequisites ──────────────────────────────────────────────────────────────

check_deps() {
  local missing=()
  if ! command -v rsvg-convert &>/dev/null && ! command -v convert &>/dev/null; then
    missing+=("rsvg-convert (librsvg2-bin) or convert (imagemagick)")
  fi
  if ! command -v zip &>/dev/null; then
    missing+=("zip")
  fi
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "❌ Missing dependencies:"
    for dep in "${missing[@]}"; do echo "   - $dep"; done
    echo ""
    echo "Install with:"
    echo "  sudo apt update && sudo apt install -y librsvg2-bin zip"
    exit 1
  fi
}

# ── Generate PNG icons from SVG ────────────────────────────────────────────────

generate_icons() {
  echo "🎨 Generating PNG icons from icon.svg..."
  for size in 16 48 128; do
    local out="$ICONS_DIR/icon${size}.png"
    if command -v rsvg-convert &>/dev/null; then
      rsvg-convert -w "$size" -h "$size" "$SVG_SRC" -o "$out"
    else
      convert -background none -resize "${size}x${size}" "$SVG_SRC" "$out"
    fi
    echo "   ✅ icon${size}.png"
  done
}

# ── Package extension into zip ─────────────────────────────────────────────────

package_zip() {
  mkdir -p "$DIST_DIR"

  local version
  version=$(grep -o '"version":\s*"[^"]*"' "$EXT_DIR/manifest.json" | head -1 | grep -o '[0-9][0-9.]*')
  local zipname="tab-out-v${version}.zip"
  local zippath="$DIST_DIR/$zipname"

  rm -f "$zippath"

  echo "📦 Packaging extension..."
  (cd "$EXT_DIR" && zip -r "$zippath" . \
    -x "*.DS_Store" \
    -x "config.local.js" \
    -x "icons/icon.svg" \
  )
  echo "   ✅ $zipname ($(du -h "$zippath" | cut -f1))"
  echo ""
  echo "📁 Output: dist/$zipname"
  echo ""
  echo "To install:"
  echo "  1. Open chrome://extensions"
  echo "  2. Drag & drop the .zip file onto the page"
  echo "  Or upload to Chrome Web Store Developer Dashboard."
}

# ── Main ───────────────────────────────────────────────────────────────────────

main() {
  echo "🔨 Tab Out — Build & Package"
  echo "─────────────────────────────"
  check_deps
  generate_icons
  package_zip
  echo ""
  echo "✅ Done!"
}

main "$@"
