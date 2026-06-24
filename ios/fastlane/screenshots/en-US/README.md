# App Store screenshots (en-US)

Add PNG screenshots here before running `./scripts/upload_ios_appstore.sh … --metadata` or `./scripts/build_ios.sh production --upload-metadata`.

Fastlane `deliver` expects one subfolder per device class. Use these folder names (create only the sizes you need to support):

| Folder | Device | Resolution (portrait) |
| --- | --- | --- |
| `iPhone 16 Pro Max` | 6.9" display | 1320 × 2868 |
| `iPhone 16 Pro` | 6.3" display | 1206 × 2622 |
| `iPhone 15 Pro Max` | 6.7" display | 1290 × 2796 |
| `iPhone 14 Plus` | 6.5" display | 1284 × 2778 |
| `iPhone 8 Plus` | 5.5" display | 1242 × 2208 |

Example layout:

```
en-US/
  iPhone 15 Pro Max/
    01_home.png
    02_coach_chat.png
    03_goals.png
```

Apple requires at least one 6.7" or 6.9" iPhone screenshot set for new apps. Check [App Store Connect screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications) for the latest required sizes.

To pull existing listing and screenshots from App Store Connect into this repo:

```bash
# Screenshots only (also pulls listing text to ios/fastlane/metadata/)
./scripts/upload_ios_appstore.sh production --download-metadata --with-screenshots

# Listing text only (no screenshots)
./scripts/upload_ios_appstore.sh production --download-metadata
```
