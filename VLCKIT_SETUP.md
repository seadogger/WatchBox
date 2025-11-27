# VLCKit Setup Guide

## Overview
This guide documents how to add VLCKit dependencies to the WatchBox project via Swift Package Manager.

## Important Note
VLCKit requires manual setup in Xcode because:
1. Platform-specific packages (MobileVLCKit for iOS, VLCKit for macOS)
2. Complex binary framework configuration
3. Platform-specific build settings

## Setup Steps

### Option 1: Using Xcode GUI (Recommended)

1. **Open the project in Xcode**
   ```bash
   cd /Users/jcox/Repos/Default/envs/devops/AppDev/WatchBox
   open WatchBox.xcodeproj
   ```

2. **Add Package Dependencies**
   - File → Add Package Dependencies...
   - Search for: `https://github.com/videolan/vlckit`

3. **Configure iOS Target**
   - Select `WatchBox` target
   - Add `MobileVLCKit` product to iOS platform

4. **Configure macOS Target**
   - Select `WatchBox` target
   - Add `VLCKit` product to macOS platform

### Option 2: Manual Package.swift (Advanced)

If VLCKit provides a Swift Package, you can reference it in your project's package dependencies.

**Note**: As of November 2025, VLCKit may require CocoaPods or manual framework installation. Check the latest documentation at:
https://code.videolan.org/videolan/VLCKit

### Alternative: Use CocoaPods

If Swift Package Manager support is incomplete:

1. **Install CocoaPods**
   ```bash
   sudo gem install cocoapods
   ```

2. **Create Podfile**
   ```ruby
   platform :ios, '26.0'
   use_frameworks!

   target 'WatchBox' do
     pod 'MobileVLCKit', '~> 3.6'
   end

   platform :osx, '26.0'

   target 'WatchBox' do
     pod 'VLCKit', '~> 3.6'
   end
   ```

3. **Install Pods**
   ```bash
   cd /Users/jcox/Repos/Default/envs/devops/AppDev/WatchBox
   pod install
   ```

4. **Open Workspace**
   ```bash
   open WatchBox.xcworkspace
   ```

## Verification

After adding VLCKit, verify the setup:

```swift
import VLCKit  // macOS
import MobileVLCKit  // iOS

// Test that classes are available
let media = VLCMedia(url: URL(string: "rtsp://example.com")!)
let player = VLCMediaPlayer()
```

## Platform-Specific Import Pattern

Use conditional compilation for imports:

```swift
#if os(iOS)
import MobileVLCKit
#elseif os(macOS)
import VLCKit
#endif
```

## Next Steps

Once VLCKit is added:
1. Create `VLCPlayerService` wrapper
2. Implement platform-specific view representables
3. Configure hardware decoding options
4. Test with sample RTSP stream

## References

- [VLCKit Documentation](https://code.videolan.org/videolan/VLCKit)
- [VLCKit iOS Example](https://code.videolan.org/videolan/VLCKit/-/tree/master/Examples)
- [MobileVLCKit CocoaPods](https://cocoapods.org/pods/MobileVLCKit)

---

**Status**: Manual setup required - complete this step in Xcode before proceeding to Phase 3 (VLCKit Integration)
