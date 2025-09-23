# Orinav

Orinav: AI-Powered Navigation for Visual Impairments

## Development Setup

**Prerequisites.** Xcode and CocoaPods.

1. Clone the repository.
2. Run `pod install`.
3. Open `BeaconNext.xcworkspace` in Xcode. Do not open `BeaconNext.xcodeproj`.
4. Create `BeaconNext/Configs/Secrets.xcconfig`. Put `TENCENT_API_KEY={key}` and `MAPBOX_ACCESS_TOKEN={token}` there.
5. Copy proprietary models to `BeaconNext/Library/Explore Features/Models`.
6. Build and run. (Development is typically done on a test device)
