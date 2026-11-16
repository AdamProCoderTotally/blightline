#!/usr/bin/env bash
# Headless Windows export. Produces one exe with the PCK embedded.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_BIN="${GODOT:-}"
if [[ -z "$GODOT_BIN" ]]; then
	if [[ -x "$HOME/.local/opt/godot/godot" ]]; then
		GODOT_BIN="$HOME/.local/opt/godot/godot"
	elif command -v godot >/dev/null 2>&1; then
		GODOT_BIN="$(command -v godot)"
	else
		echo "Godot 4.7.x not found. Run tools/install_godot.sh or set GODOT=/path/to/godot." >&2
		exit 1
	fi
fi

VERSION="$("$GODOT_BIN" --version)"
TEMPLATE="$HOME/.local/share/godot/export_templates/4.7.2.stable/windows_release_x86_64.exe"
if [[ ! -f "$TEMPLATE" ]]; then
	echo "Windows release template missing: $TEMPLATE" >&2
	echo "Install it with tools/install_godot.sh (Godot 4.7.2 export templates)." >&2
	exit 1
fi

OUT="$ROOT/build/windows/BLIGHTLINE.exe"
mkdir -p "$(dirname "$OUT")"
"$GODOT_BIN" --headless --path "$ROOT" --export-release "Windows Desktop" "$OUT"

python3 - "$OUT" << 'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
data = path.read_bytes()
if data[:2] != b"MZ":
    sys.exit("export is not a Windows executable")
if b"GDPC" not in data:
    sys.exit("PCK magic GDPC was not embedded in the exe")
if b"remaining_hp_plus_shield" not in data:
    sys.exit("game.json was not packed into the exe")
sidecar = path.with_suffix(".pck")
if sidecar.exists():
    sys.exit(f"unexpected sidecar pack: {sidecar}")
print(f"ok {path} ({path.stat().st_size} bytes), embedded pck")
PY
echo "Exported $OUT with $VERSION"
