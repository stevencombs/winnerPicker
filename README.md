# retroCombs winnerPicker

<p align="center">
  <img src="Resources/AppIcon-1024.png" width="160" alt="retroCombs winnerPicker icon">
</p>

A native macOS app that picks one winner from a typed or pasted list of names. Built for livestreams and giveaways: large type, a five-second shuffle with drumroll, then a fanfare page with confetti.

## Requirements

- macOS 14 or later
- [Swift](https://www.swift.org/install/) or Xcode Command Line Tools (`xcode-select --install`)

## Build and install

```bash
git clone https://github.com/stevencombs/winnerPicker.git
cd winnerPicker
chmod +x Scripts/build-app.sh
./Scripts/build-app.sh
```

The script builds a release binary and packages:

`dist/retroCombs winnerPicker.app`

Copy that app to `/Applications` or your Desktop, then double-click to launch.

To run from source without packaging an app:

```bash
cd winnerPicker
swift run
```

The first time you open the `.app`, macOS Gatekeeper may block it because it is unsigned. Right-click the app, choose **Open**, then confirm.

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
Scripts/build-app.sh          Release build and .app packaging
Scripts/generate_sounds.py    Regenerates the bundled WAV files
```

To rebuild the drumroll and fanfare sounds:

```bash
python3 Scripts/generate_sounds.py
./Scripts/build-app.sh
```

## License

MIT License — see [LICENSE](LICENSE).
