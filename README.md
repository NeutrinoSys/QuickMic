# QuickMic

A simple macOS menubar app for quickly switching microphone inputs and resetting audio/dictation services.

## What It Does

**Primary Features:**
- **Quick Microphone Switching**: Instantly switch between audio input devices from the menubar
- **Audio Service Reset**: Nuclear option to reset all dictation and audio services

Perfect for fixing macOS voice transcription (dictation) issues that occur after docking/undocking your laptop.

## Features

### Switch Microphone
Quickly switch between available audio input devices:
- Built-in Microphone
- External USB audio interfaces (e.g., Focusrite)
- Other connected audio inputs
- Shows checkmark next to currently active device

### Reset Dictation (Nuclear Option)
Resets these services when switching inputs isn't enough:
- `localspeechrecognition`
- `assistant_service`
- `corespeechd`
- `assistantd`
- `coreaudiod`

## Building

```bash
./build.sh
```

This will create `build/QuickMic.app`

## Installing

Copy the app to your Applications folder:

```bash
cp -r build/QuickMic.app /Applications/
```

Then open it from Applications or Spotlight. A microphone icon will appear in your menubar.

## Using

1. Click the microphone icon in your menubar
2. **Switch Microphone** → Hover to see all available inputs and select one
3. **Reset Dictation (Nuclear)** → Use this if switching doesn't fix the issue (requires password)
4. You'll see a notification when operations complete

## Setting Up Keyboard Shortcut (Optional)

To trigger actions with keyboard shortcuts:

1. Open **System Settings** → **Keyboard** → **Keyboard Shortcuts**
2. Select **App Shortcuts** from the left sidebar
3. Click the **+** button
4. **Application**: Select "QuickMic.app"
5. **Menu Title**: Type exactly the menu item name (e.g., `Reset Dictation (Nuclear)`)
6. **Keyboard Shortcut**: Press your desired shortcut (e.g., ⌘⌥⇧R)
7. Click **Add**

## Requirements

- macOS 11.0 or later
- Swift compiler (comes with Xcode Command Line Tools)

## Troubleshooting

If you get "QuickMic.app can't be opened":
1. Right-click the app and select "Open"
2. Click "Open" in the security dialog
3. The app will now run normally

## Installation on Multiple Machines

Clone and build on any Mac:

```bash
git clone https://github.com/NeutrinoSys/QuickMic.git
cd QuickMic
./build.sh
cp -r build/QuickMic.app /Applications/
```

## License

MIT License - Feel free to modify and distribute
