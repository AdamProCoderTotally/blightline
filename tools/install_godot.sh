#!/usr/bin/env bash
# Install the Godot 4.7.2 editor and the Windows export templates this project was built with.
set -euo pipefail

VERSION="4.7.2"
EDITOR_URL="https://github.com/godotengine/godot/releases/download/${VERSION}-stable/Godot_v${VERSION}-stable_linux.x86_64.zip"
EDITOR_SHA="cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4"
TEMPLATES_URL="https://github.com/godotengine/godot/releases/download/${VERSION}-stable/Godot_v${VERSION}-stable_export_templates.tpz"
TEMPLATES_SHA="f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011"

PREFIX="${GODOT_PREFIX:-$HOME/.local/opt/godot}"
TEMPLATE_DIR="${GODOT_TEMPLATES:-$HOME/.local/share/godot/export_templates/${VERSION}.stable}"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

mkdir -p "$PREFIX" "$TEMPLATE_DIR"
curl -L --fail --retry 3 -o "$WORKDIR/godot.zip" "$EDITOR_URL"
echo "$EDITOR_SHA  $WORKDIR/godot.zip" | sha256sum -c -
unzip -o -q "$WORKDIR/godot.zip" -d "$PREFIX"
bin="$(find "$PREFIX" -maxdepth 2 -type f -name "Godot_v${VERSION}-stable_linux.x86_64" | head -1)"
chmod +x "$bin"
ln -sfn "$bin" "$PREFIX/godot"

curl -L --fail --retry 3 -o "$WORKDIR/templates.tpz" "$TEMPLATES_URL"
echo "$TEMPLATES_SHA  $WORKDIR/templates.tpz" | sha256sum -c -
unzip -o -q "$WORKDIR/templates.tpz" "templates/windows_*x86_64*" -d "$WORKDIR"
cp -a "$WORKDIR/templates/." "$TEMPLATE_DIR/"
echo "Godot ${VERSION} installed at $PREFIX/godot"
echo "Windows templates installed at $TEMPLATE_DIR"
