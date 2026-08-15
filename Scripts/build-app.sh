#!/bin/zsh
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

swift build -c release

app="$root/dist/retroCombs winnerPicker.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"

cp "$root/.build/release/WinnerPicker" "$app/Contents/MacOS/WinnerPicker"
cp "$root/Resources/Info.plist" "$app/Contents/Info.plist"
echo -n "APPL????" > "$app/Contents/PkgInfo"

if [[ -f "$root/Resources/AppIcon.icns" ]]; then
    cp "$root/Resources/AppIcon.icns" "$app/Contents/Resources/AppIcon.icns"
fi

for sound in drumroll.wav fanfare.wav; do
    if [[ -f "$root/Resources/$sound" ]]; then
        cp "$root/Resources/$sound" "$app/Contents/Resources/$sound"
    fi
done

echo "Built $app"
