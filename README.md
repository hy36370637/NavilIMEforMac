# NavilIME — Korean Input Method for macOS, Tailored for Emacs Users

## About
- Tested on emacs-plus 30.2, macOS 15.7.4
- Prefers continuous 2-beolsik input, similar to Emacs built-in Korean input method
- Supports Hanja and special character conversion via F9 key

## The Inevitable Struggle of Korean Keyboard Users
- Primarily using MacBook with Emacs/org-mode
- The painful keyboard switching problem between macOS and Emacs is a familiar struggle for Korean users

## Patches
- **For Emacs**: Automatically switches to macOS English keyboard when Emacs gains focus
- **ㅆ jongseong fix**: Added `"tt":Jongsung.Ssangsios` — one line fix in `Keyboard002.swift`
- **Hanja & symbol conversion (F9)**: Press F9 while composing a Korean syllable to open a candidate popup. Select with mouse double-click or arrow keys + Enter. Press F9 again or ESC to dismiss. Powered by a JSON table ported from Emacs `hanja-util.el` (572 entries, covering both Hanja and special symbols)
- **Lightweight build**: ARM64 only, 2-beolsik only

## Hanja Conversion — Supported Apps
- Emacs, Upnote, Safari, Chrome, TextEdit and most standard macOS apps
- iTerm2: limited support due to terminal IME constraints

## With the Help of AI
- I am not a developer
- Started this to solve the keyboard switching inconvenience that Korean layout users face
- Fortunately, living in a good era — solved with the help of AI

## Build
Swift version 5 is required (Swift 6 causes build errors)
```bash
cd ~/Build/NavilIMEforMac
rm -rf ~/Library/Developer/Xcode/DerivedData/NavilIME-*
xcodebuild -project NavilIME.xcodeproj \
           -scheme NavilIME \
           -configuration Release \
           CODE_SIGN_IDENTITY="" \
           CODE_SIGNING_REQUIRED=NO \
           SWIFT_VERSION=5 \
           ARCHS=arm64 \
           ONLY_ACTIVE_ARCH=NO \
           build 2>&1 | tail -3
```

## Credits
- Special thanks to the original author, **navilera**
- https://github.com/navilera/NavilIMEforMac
