# retroCombs winnerPicker

<p align="center">
  <img src="Resources/AppIcon-1024.png" width="160" alt="retroCombs winnerPicker icon">
</p>

A native macOS app that picks one winner from a typed or pasted list of names. Built for livestreams and giveaways: large type, a five-second shuffle with drumroll, then a fanfare page with confetti.

## Requirements

- macOS 14 or later
- Xcode Command Line Tools (`xcode-select --install`), which provide `swift`, or a Swift toolchain on `PATH`
- `zsh`, `codesign`, and `ditto`, which ship with macOS

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

The installed app is the binary, icon, and sounds inside the bundle. It does not read this checkout. Quit retroCombs winnerPicker before installing again so the copy already in Applications can be replaced.

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

1. Type or paste names into the text box. Separate them with commas. Newlines work too, so a pasted column of names is fine.
2. Click **Winner**, or press Return.
3. Watch a five-second shuffle while a drumroll plays. That pause is long enough for color commentary.
4. The fanfare page reveals the winner with confetti and a brass sting.
5. Use **Pick Again** for another draw from the same list, or **New Drawing** to edit the names.

Empty entries and extra commas are ignored.

### Example

```text
Ada Lovelace, Grace Hopper, Alan Turing, Katherine Johnson, Margaret Hamilton
```

## What a draw does

1. Splits the list on commas and newlines, then trims whitespace
2. Shuffles every name
3. Cycles through the shuffled names for five seconds, starting fast and slowing down
4. Pauses on **AND THE WINNER IS**
5. Reveals one winner, plays the fanfare, and starts confetti

## Project layout

```text
Package.swift                 Swift package manifest
Sources/WinnerPicker/         SwiftUI app source
Resources/                    App icon, Info.plist, drumroll, and fanfare audio
Scripts/build-app.sh          Release build, ad-hoc sign, and install
Scripts/generate_sounds.py    Regenerates the bundled WAV files
```

To rebuild the drumroll and fanfare sounds:

```zsh
python3 Scripts/generate_sounds.py
zsh Scripts/build-app.sh --install
```

## License

MIT License — see [LICENSE](LICENSE).
