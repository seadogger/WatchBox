# WatchBox

A modern, universal Swift application for monitoring multiple security cameras with RTSP streaming, auto-discovery, and dynamic grid layout.

![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20visionOS-lightgrey)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![iOS](https://img.shields.io/badge/iOS-26.0+-blue)
![macOS](https://img.shields.io/badge/macOS-15.0+-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

### Core Functionality
- **Multi-Camera Grid View** - Monitor multiple cameras simultaneously in a dynamic, responsive grid layout
- **RTSP Streaming** - Full support for RTSP/RTMP/HTTP video streams with hardware-accelerated decoding
- **Auto-Discovery** - Automatically detect cameras on your network using ONVIF and port scanning
- **Manual Configuration** - Add cameras manually with RTSP URL, username, and password
- **Secure Storage** - Camera credentials stored securely in iOS/macOS Keychain
- **Cross-Platform** - Universal app supporting iOS, macOS, and visionOS

### Video Streaming
- Hardware-accelerated video decoding
- Support for H.264, H.265, MJPEG, and MPEG-4 codecs
- Low-latency streaming with configurable network caching
- Automatic reconnection for failed streams
- Stream health monitoring

### Network Discovery
- **ONVIF Discovery** - WS-Discovery multicast protocol for ONVIF-compliant cameras
- **Port Scanning** - Scan subnet for common RTSP ports (554, 8554, 88, 7447, 5000)
- **Multicast Detection** - Listen for multicast stream announcements
- **Subnet Configuration** - Specify custom subnets for discovery

### User Interface
- **Dynamic Grid Layout** - Automatically adjusts columns based on screen size and camera count
- **Drag-to-Reorder** - Organize cameras in your preferred layout
- **Full-Screen View** - Tap any camera to expand to full screen
- **Dark Mode** - Full dark mode support
- **Platform-Specific** - Native UI patterns for iOS and macOS

## Screenshots

> Screenshots coming soon

## Requirements

- **iOS** 26.0 or later
- **macOS** 15.0 or later
- **visionOS** 2.0 or later
- **Xcode** 26.0.1 or later
- **Swift** 6.0

## Installation

### Clone the Repository

```bash
git clone https://github.com/seadogger/WatchBox.git
cd WatchBox
```

### Open in Xcode

```bash
open WatchBox.xcodeproj
```

### Install Dependencies

Dependencies are managed via Swift Package Manager and will be automatically resolved when you build the project:

- **VLCKit** (macOS) - Video streaming and codec support
- **MobileVLCKit** (iOS) - Video streaming and codec support

### Build and Run

1. Select your target device or simulator
2. Press `Cmd+R` to build and run

## Usage

### Adding Cameras Manually

1. Tap the **+** button in the camera list
2. Enter the following information:
   - Camera name (e.g., "Front Door")
   - RTSP URL (e.g., `rtsp://192.168.1.100:554/stream1`)
   - Username (optional)
   - Password (optional)
3. Tap **Save**

### Auto-Discovery

1. Tap the **Discover** button
2. Wait for the app to scan your network
3. Select cameras from the discovered list
4. Tap **Add Selected Cameras**

### Managing Cameras

- **Edit** - Tap a camera in the list to edit its settings
- **Delete** - Swipe left on a camera to delete
- **Reorder** - Drag cameras in the grid to reorder

### Viewing Streams

- **Grid View** - View all cameras simultaneously in the main grid
- **Full Screen** - Tap any camera to expand to full screen
- **Pull to Refresh** - Pull down to reconnect all cameras

## Architecture

WatchBox follows a clean architecture pattern with MVVM:

```
Views (SwiftUI) → ViewModels → Services → Repositories → Data Sources (CoreData/Network)
```

### Key Components

- **Models** - Domain models and CoreData entities
- **Views** - SwiftUI views for UI
- **ViewModels** - Business logic and state management
- **Services** - Network, streaming, and discovery services
- **Repositories** - Data access layer
- **Utilities** - Helper functions and extensions

For detailed architecture information, see [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md).

## Technology Stack

- **SwiftUI** - Modern declarative UI framework
- **CoreData** - Camera configuration persistence
- **Keychain Services** - Secure credential storage
- **Network Framework** - Camera discovery and port scanning
- **URLSession** - ONVIF HTTP requests
- **VLCKit** - RTSP streaming and video decoding
- **Swift Concurrency** - async/await for asynchronous operations

## Security

WatchBox takes security seriously:

- **Keychain Storage** - All camera passwords are stored in the iOS/macOS Keychain, not in CoreData
- **RTSP Authentication** - Supports both Basic and Digest authentication
- **Input Validation** - All user inputs are validated and sanitized
- **SSL/TLS** - HTTPS validation for ONVIF requests

## Supported Cameras

WatchBox supports any camera that provides an RTSP stream, including:

- ONVIF-compliant cameras (auto-discovery)
- Hikvision
- Dahua
- Axis
- Reolink
- Amcrest
- Foscam
- And many more...

### RTSP URL Formats

Common RTSP URL formats for popular brands:

**Hikvision:**
```
rtsp://username:password@192.168.1.100:554/Streaming/Channels/101
```

**Dahua:**
```
rtsp://username:password@192.168.1.100:554/cam/realmonitor?channel=1&subtype=0
```

**Axis:**
```
rtsp://username:password@192.168.1.100:554/axis-media/media.amp
```

**Reolink:**
```
rtsp://username:password@192.168.1.100:554/h264Preview_01_main
```

## Development

### Project Structure

```
WatchBox/
├── WatchBox/              # Main application
│   ├── Models/           # Domain models and CoreData entities
│   ├── Views/            # SwiftUI views
│   ├── ViewModels/       # View models
│   ├── Services/         # Business logic services
│   │   ├── Discovery/    # ONVIF and port scanning
│   │   ├── Streaming/    # VLCKit integration
│   │   ├── Network/      # Network utilities
│   │   └── Storage/      # Data persistence
│   └── Utilities/        # Helper functions
├── WatchBoxTests/         # Unit tests
└── WatchBoxUITests/       # UI tests
```

### Building from Source

1. Clone the repository
2. Open `WatchBox.xcodeproj` in Xcode
3. Select your target (iOS or macOS)
4. Build with `Cmd+B`

### Running Tests

```bash
# Run all tests
xcodebuild test -scheme WatchBox -destination 'platform=iOS Simulator,name=iPhone 16'

# Run specific test
xcodebuild test -scheme WatchBox -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WatchBoxTests/CameraRepositoryTests
```

## Roadmap

See [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) for the complete implementation roadmap.

### Phase 1 - Foundation ✅
- [x] Project setup
- [ ] VLCKit integration
- [ ] CoreData model
- [ ] Basic camera CRUD

### Phase 2 - Discovery
- [ ] ONVIF discovery
- [ ] Port scanning
- [ ] Discovery UI

### Phase 3 - Streaming
- [ ] VLCKit player service
- [ ] Video display view
- [ ] Stream manager

### Phase 4 - Grid View
- [ ] Dynamic grid layout
- [ ] Multi-stream management
- [ ] Performance optimization

### Phase 5 - Polish
- [ ] Platform-specific features
- [ ] Settings
- [ ] UI refinement

### Phase 6 - Testing
- [ ] Unit tests
- [ ] Integration tests
- [ ] Real-world testing

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Guidelines

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow Swift API Design Guidelines
- Use SwiftLint for code formatting
- Write unit tests for new features
- Document public APIs

## Troubleshooting

### Camera Not Connecting

1. **Check RTSP URL** - Ensure the URL format is correct
2. **Verify Credentials** - Check username and password
3. **Test Network** - Ensure camera is reachable on the network
4. **Check Firewall** - Ensure port 554 (or custom port) is not blocked
5. **Try TCP** - Some cameras require RTSP over TCP instead of UDP

### Discovery Not Finding Cameras

1. **Same Subnet** - Ensure device is on the same network as cameras
2. **ONVIF Support** - Not all cameras support ONVIF discovery
3. **Firewall** - Check that multicast traffic is allowed
4. **Manual Entry** - You can always add cameras manually

### Performance Issues

1. **Reduce Stream Count** - Limit concurrent streams (max 16)
2. **Lower Resolution** - Use substream instead of mainstream
3. **Network Bandwidth** - Ensure sufficient bandwidth for all streams
4. **Hardware** - Older devices may struggle with many streams

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [VLCKit](https://code.videolan.org/videolan/VLCKit) - Video streaming and codec support
- ONVIF specification - Camera discovery protocol
- The Swift community for excellent frameworks and tools

## Contact

- **Developer**: Jason Seeliger
- **GitHub**: [@seadogger](https://github.com/seadogger)
- **Project Link**: [https://github.com/seadogger/WatchBox](https://github.com/seadogger/WatchBox)

## Support

If you find this project helpful, please consider giving it a ⭐️ on GitHub!

---

Made with ❤️ in Swift
