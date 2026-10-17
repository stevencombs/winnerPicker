#!/bin/zsh
# Build and optionally install retroCombs winnerPicker.
#
#   zsh Scripts/build-app.sh
#   zsh Scripts/build-app.sh --install
#
# Invoke with zsh so this still runs after a sync tool clears the script's +x bit.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

install=0
for arg in "$@"; do
    case "$arg" in
        --install) install=1 ;;
        -h|--help)
            echo "Usage: zsh Scripts/build-app.sh [--install]"
            echo "  --install  copy the signed app to /Applications, or ~/Applications if that is not writable"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            echo "Usage: zsh Scripts/build-app.sh [--install]" >&2
            exit 1
            ;;
    esac
done

swift build -c release

app="$root/dist/retroCombs winnerPicker.app"
binary="$app/Contents/MacOS/WinnerPicker"

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"

cp "$root/.build/release/WinnerPicker" "$binary"
# cp keeps whatever mode swift build produced. Set the bit explicitly so a
# freshly built bundle is launchable even if that mode was already 644.
chmod 755 "$binary"

cp "$root/Resources/Info.plist" "$app/Contents/Info.plist"
echo -n "APPL????" > "$app/Contents/PkgInfo"

# Fonts, artwork, sounds, and the icon. Info.plist is installed above.
for resource in "$root"/Resources/*; do
    [[ -f "$resource" ]] || continue
    name="${resource:t}"
    [[ "$name" == "Info.plist" ]] && continue
    cp "$resource" "$app/Contents/Resources/$name"
done

# On a Mac, rebuild AppIcon.icns from the 1024 master with the system tools
# so every size from 16 through 1024 is packed by iconutil. The icns already
# in Resources is the fallback when sips or iconutil is not on PATH.
master="$root/Resources/AppIcon-1024.png"
if [[ -x /usr/bin/sips && -x /usr/bin/iconutil && -f "$master" ]]; then
    iconset="$(mktemp -d)/AppIcon.iconset"
    mkdir -p "$iconset"
    /usr/bin/sips -z 16 16 "$master" --out "$iconset/icon_16x16.png" >/dev/null
    /usr/bin/sips -z 32 32 "$master" --out "$iconset/icon_16x16@2x.png" >/dev/null
    /usr/bin/sips -z 32 32 "$master" --out "$iconset/icon_32x32.png" >/dev/null
    /usr/bin/sips -z 64 64 "$master" --out "$iconset/icon_32x32@2x.png" >/dev/null
    /usr/bin/sips -z 128 128 "$master" --out "$iconset/icon_128x128.png" >/dev/null
    /usr/bin/sips -z 256 256 "$master" --out "$iconset/icon_128x128@2x.png" >/dev/null
    /usr/bin/sips -z 256 256 "$master" --out "$iconset/icon_256x256.png" >/dev/null
    /usr/bin/sips -z 512 512 "$master" --out "$iconset/icon_256x256@2x.png" >/dev/null
    /usr/bin/sips -z 512 512 "$master" --out "$iconset/icon_512x512.png" >/dev/null
    /usr/bin/sips -z 1024 1024 "$master" --out "$iconset/icon_512x512@2x.png" >/dev/null
    # sips resamples with a blur that melts the four rings and the joystick
    # at 16 and 32. Those two masters are drawn so the stick, red buttons,
    # dark outline, and rainbow edge stay solid. iconutil still packs them.
    if [[ -f "$root/Resources/AppIcon-16.png" ]]; then
        cp "$root/Resources/AppIcon-16.png" "$iconset/icon_16x16.png"
    fi
    if [[ -f "$root/Resources/AppIcon-32.png" ]]; then
        cp "$root/Resources/AppIcon-32.png" "$iconset/icon_16x16@2x.png"
        cp "$root/Resources/AppIcon-32.png" "$iconset/icon_32x32.png"
    fi
    /usr/bin/iconutil -c icns "$iconset" -o "$app/Contents/Resources/AppIcon.icns"
    rm -rf "${iconset:h}"
fi

# swift build leaves an ad-hoc linker signature on the bare Mach-O
# (flags include linker-signed, Sealed Resources=none). Once that binary
# sits in a bundle, codesign --verify fails with "code has no resources
# but signature indicates they must be present" because nothing wrote
# Contents/_CodeSignature/CodeResources. Sign the finished bundle so the
# executable, Info.plist, and Resources are sealed together.
/usr/bin/codesign --force --sign - "$app"
/usr/bin/codesign --verify --deep --strict "$app"

echo "Built $app"

if [[ "$install" == 1 ]]; then
    if [[ -w /Applications ]]; then
        dest="/Applications"
    else
        dest="${HOME}/Applications"
        mkdir -p "$dest"
    fi

    target="$dest/retroCombs winnerPicker.app"
    rm -rf "$target"
    # ditto preserves the signature, resource metadata, and file modes.
    /usr/bin/ditto "$app" "$target"
    # The mode is not part of the signature. Set it again on the installed
    # copy so a sync of dist/ cannot strand the app that actually launches.
    chmod 755 "$target/Contents/MacOS/WinnerPicker"

    echo "Installed $target"
fi
