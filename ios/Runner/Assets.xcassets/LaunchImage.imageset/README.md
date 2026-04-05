# Launch Screen Assets

The PNGs here are shown by `LaunchScreen.storyboard` while the app loads. They are generated from `assets/icon/appstore.png` (256 / 512 / 768 px) so `flutter build ipa` does not flag the default Flutter placeholders.

To refresh after changing the app icon:

```bash
SRC=assets/icon/appstore.png
DEST=ios/Runner/Assets.xcassets/LaunchImage.imageset
sips -z 256 256  "$SRC" --out "$DEST/LaunchImage.png"
sips -z 512 512  "$SRC" --out "$DEST/LaunchImage@2x.png"
sips -z 768 768  "$SRC" --out "$DEST/LaunchImage@3x.png"
```

You can also replace them from Xcode: `open ios/Runner.xcworkspace` → **Runner** → **Assets.xcassets** → **LaunchImage**.