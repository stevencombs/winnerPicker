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

if [[ -f "$root/Resources/AppIcon.icns" ]]; then
    cp "$root/Resources/AppIcon.icns" "$app/Contents/Resources/AppIcon.icns"
fi

for sound in drumroll.wav fanfare.wav; do
    if [[ -f "$root/Resources/$sound" ]]; then
        cp "$root/Resources/$sound" "$app/Contents/Resources/$sound"
    fi
done

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
