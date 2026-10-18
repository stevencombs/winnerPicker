# retroCombs winnerPicker

<p align="center">
  <img src="Resources/AppIcon-1024.png" width="160" alt="retroCombs winnerPicker icon">
</p>

A native macOS app for drawing retroCombs members-only giveaway winners on a Sunday livestream. Setup stays off air. Go Live switches to a 16:9 screen: logo, prize, name shuffle, entrant chips, and a YouTube membership QR code. Each winner gets the drumroll and fanfare, then pixel fireworks and a claim countdown.

## Requirements

- macOS 14 or later
- Xcode Command Line Tools (`xcode-select --install`), which provide `swift`, or a Swift toolchain on `PATH`
- `zsh`, `codesign`, and `ditto`, which ship with macOS. `sips` and `iconutil` pack the app icon during the build.

## Build and install

Launch the copy in `/Applications` or `~/Applications`. This checkout is only the source tree. `dist/` and `.build/` are gitignored build output, and on a Google Drive / Insync folder a later sync can clear the executable bit on `Contents/MacOS/WinnerPicker`. Launchd then reports `Launchd job spawn failed` / `permission denied`.

After the repo is on the Mac, one command builds a release app, sets the executable bit, ad-hoc signs the finished bundle, and installs it. `/Applications` is used when that folder is writable; otherwise the script creates `~/Applications` and installs there.

From the repo directory:

```zsh
zsh Scripts/build-app.sh --install
```

The script locates the checkout from its own path, so a full path works from any directory:

```zsh
zsh /path/to/winnerPicker/Scripts/build-app.sh --install
```

Calling it through `zsh` matters: the scripts are `100755` in git, but a sync can leave them `100644`, and `zsh` does not need the executable bit.

The installed app is the binary plus the icon, fonts, artwork, and sounds inside the bundle. It does not read this checkout. Quit retroCombs winnerPicker before installing again so the copy already in Applications can be replaced.

To build without installing, omit the flag. The bundle is written to `dist/retroCombs winnerPicker.app`. The script exits with an error if `codesign --verify --deep --strict` fails.

```zsh
zsh Scripts/build-app.sh
```

`swift run` still builds from source for a quick check. That binary is under `.build/` inside the checkout, so prefer the installed app when this folder is synced.

The signature is ad-hoc (no Developer ID). The first launch can still trip Gatekeeper. Right-click the app in Applications, choose **Open**, then confirm.

### Moving the app to another Mac

Pack a zip with `ditto` or Finder's **Compress**. Both keep the executable bit and the signature. Expand that zip on the other Mac.

```zsh
ditto -c -k --keepParent "/Applications/retroCombs winnerPicker.app" winnerPicker.zip
```

```zsh
ditto -x -k winnerPicker.zip /Applications
```

If `/Applications` is not writable, expand into `~/Applications` instead.

### Synced git checkouts

After an Insync sync, `git status` may show `mode change 100755 => 100644` on `Scripts/` even though the file contents are unchanged. This clone can ignore mode-only differences:

```zsh
git config core.fileMode false
```

That setting stays on this machine. Keep running the build as `zsh Scripts/build-app.sh`.

## How to use it

1. Paste entrant names from the members-only sign-up. Commas and new lines both work. The count updates as you type.
2. Pick how many winners (1–10), name each prize or use the same prize for all, and set the claim timer. It starts at 2:00.
3. Click **Go Live**. The name editor leaves the screen.
4. Press Space to draw. A five-second shuffle plays with the drumroll, holds on **AND THE WINNER IS**, then reveals the name with the fanfare and pixel fireworks.
5. The winner has that long to claim in chat. **Draw Again** if they are a no-show. **Next Prize** draws the next winner. After the last one, the recap lists everyone.

Each person can win once. A redraw also removes the no-show from the rest of the session.

### Keys

| Key | Action |
| --- | --- |
| Space | Draw, or go to the next prize |
| R | Redraw the current prize |
| N | New list (back to setup) |
| F | Full screen |
| Esc | Back to setup |

### Example

```text
PixelPete64, SIDChipSally, ByteBandit
FloppyMcDisk
DatasetteDan
```

## What a draw does

1. Splits the list on commas and newlines, trims whitespace, and drops empty or duplicate names
2. Removes anyone who already won, and anyone who was redrawn as a no-show
3. Shuffles the people still in the pool
4. Cycles through those names for five seconds, starting fast and slowing down, while the drumroll plays
5. Pauses on **AND THE WINNER IS**
6. Reveals the winner, plays the fanfare, and starts the claim countdown

## Project layout

```text
Package.swift                 Swift package manifest
Sources/WinnerPicker/         SwiftUI app source
Resources/                    Icon, fonts, badges, logo, Info.plist, drumroll, and fanfare
Scripts/build-app.sh          Release build, icon pack, ad-hoc sign, and install
Scripts/generate_sounds.py    Regenerates the bundled WAV files
```

The app icon is the joystick logo on a beige rounded tile, with a dark outline, an orange, yellow, green, and blue edge, and a few rainbow pixel-firework bursts. `Resources/AppIcon-1024.png` is the master. On a Mac the build packs every size from 16 through 1024 with `sips` and `iconutil`, then copies `AppIcon-16.png` and `AppIcon-32.png` over the two smallest outputs so the stick, the red buttons, and the bursts stay solid. `Resources/AppIcon.icns` is the committed icon, including those sizes, for machines that build without `sips`. `CFBundleIconFile` is `AppIcon`.

Setup scales to the window, so the form fits at the default size and grows to fill a full-screen display. The draw, winner, and recap screens are a 1920×1080 stage scaled to fit, letterboxed when the window is not 16:9.

Press Start 2P and VT323 are OFL fonts in `Resources/`. See `Resources/Fonts-OFL.txt`. The app registers them at launch with `CTFontManagerRegisterFontsForURL`.

To rebuild the drumroll and fanfare sounds:

```zsh
python3 Scripts/generate_sounds.py
zsh Scripts/build-app.sh --install
```

## License

MIT License — see [LICENSE](LICENSE).
The bundled fonts stay under the SIL Open Font License.
