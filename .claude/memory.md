# WatchBox Project Memory Bank

## Project Context

**Project Name**: WatchBox
**Repository**: https://github.com/seadogger/WatchBox.git
**Developer**: Jason Seeliger (@seadogger)
**Created**: November 27, 2025
**Platform**: Universal app (iOS 26.0+, macOS 15.0+, visionOS 2.0+)
**Language**: Swift 6.0
**Xcode Version**: 26.0.1

## Project Purpose

WatchBox is a security camera monitoring application that allows users to:
1. View multiple RTSP camera streams in a dynamic grid layout
2. Auto-discover cameras using ONVIF protocol and port scanning
3. Manually add cameras with RTSP URLs and credentials
4. Securely store credentials in iOS/macOS Keychain
5. Monitor cameras across iOS, macOS, and visionOS platforms

## Current Project State

### Completed
- ✅ Project initialized from Xcode template
- ✅ Initial commit to GitHub
- ✅ Implementation plan created ([IMPLEMENTATION_PLAN.md](../IMPLEMENTATION_PLAN.md))
- ✅ README.md created with comprehensive documentation
- ✅ Claude rules and memory bank established

### In Progress
- 🔄 Phase 1: Foundation & Dependencies (NOT STARTED)

### Not Started
- ⏸️ Phase 2: Network Discovery
- ⏸️ Phase 3: VLCKit Integration & Streaming
- ⏸️ Phase 4: Grid View & Multi-Stream
- ⏸️ Phase 5: Cross-Platform Polish
- ⏸️ Phase 6: Testing & Hardening

## Key Technical Decisions

### Decision 1: RTSP Streaming Library (Resolved)
**Problem**: AVFoundation doesn't support RTSP natively
**Options Considered**:
- Option A: Pure Swift implementation (Network.framework + VideoToolbox)
- Option B: VLCKit (Swift-friendly C wrapper)
- Option C: Hybrid approach

**Decision**: Use VLCKit (Option B)
**Rationale**:
- Battle-tested RTSP support
- Supports all codecs (H.264, H.265, MJPEG, MPEG-4)
- Hardware acceleration built-in
- Much faster implementation timeline (3 weeks vs 6-8 weeks)
- Proven compatibility with major camera brands
- Active maintenance and community support

**Decided By**: User preference
**Date**: November 27, 2025

### Decision 2: Architecture Pattern (Resolved)
**Pattern**: MVVM + Clean Architecture + Repository Pattern
**Rationale**:
- Clear separation of concerns
- Testable business logic
- SwiftUI-friendly (ObservableObject ViewModels)
- Platform-agnostic business logic
- Easy to mock for testing

### Decision 3: Data Persistence (Resolved)
**Camera Configurations**: CoreData
**Credentials**: Keychain Services (NOT CoreData for security)
**Rationale**:
- CoreData for structured camera data
- Keychain for secure password storage
- No third-party persistence libraries needed

## Project Structure

```
WatchBox/
├── .claude/
│   ├── rules.md              # Project coding standards
│   └── memory.md             # This file
├── WatchBox/
│   ├── WatchBoxApp.swift     # App entry point
│   ├── ContentView.swift     # Template view (to be replaced)
│   ├── Persistence.swift     # CoreData stack
│   ├── WatchBox.xcdatamodeld/  # CoreData model
│   └── Assets.xcassets/      # Assets
├── WatchBoxTests/            # Unit tests
├── WatchBoxUITests/          # UI tests
├── IMPLEMENTATION_PLAN.md    # Detailed implementation plan
└── README.md                 # Project documentation
```

## Important Files & Locations

### Core Files
- **App Entry**: `WatchBox/WatchBoxApp.swift`
- **CoreData Model**: `WatchBox/WatchBox.xcdatamodeld/WatchBox.xcdatamodel/contents`
- **Persistence**: `WatchBox/Persistence.swift`
- **Project Config**: `WatchBox.xcodeproj/project.pbxproj`

### Documentation
- **Implementation Plan**: `IMPLEMENTATION_PLAN.md`
- **README**: `README.md`
- **Claude Rules**: `.claude/rules.md`

## CoreData Model (Current State)

### Existing Entities
- **Item** (Template entity - TO BE REMOVED)
  - timestamp: Date?

### Planned Entities (NOT YET IMPLEMENTED)
- **Camera**
  - id: UUID
  - name: String
  - rtspURL: String
  - username: String?
  - ipAddress: String
  - port: Int16
  - manufacturer: String?
  - model: String?
  - isActive: Bool
  - gridPosition: Int16
  - dateAdded: Date
  - lastConnected: Date?
  - thumbnailData: Data?

- **StreamProfile**
  - id: UUID
  - name: String
  - rtspURL: String
  - resolution: String
  - fps: Int16
  - isDefault: Bool
  - camera: Camera (relationship)

## Dependencies (Current State)

### Installed
- None (template project only uses Apple frameworks)

### To Be Added (Phase 1)
- **VLCKit** (macOS) - via Swift Package Manager
- **MobileVLCKit** (iOS) - via Swift Package Manager

### Apple Frameworks in Use
- SwiftUI - UI framework
- CoreData - Data persistence
- Foundation - Base functionality
- Testing - Unit testing
- XCTest - UI testing

## User Preferences & Requirements

### Target Platforms
- ✅ iOS (primary)
- ✅ macOS (primary)
- ✅ visionOS (supported)

### Grid View Requirements
- Dynamic grid that adapts to number of cameras
- No fixed maximum (practical limit ~16 concurrent streams)
- Responsive to screen size and orientation

### Discovery Requirements
- ONVIF WS-Discovery protocol
- Port scanning (554, 8554, 88, 7447, 5000)
- User-specified subnet
- Multicast detection

### Streaming Requirements
- Live streaming only (no recording)
- Hardware-accelerated decoding
- Support all common codecs
- Low latency preferred

### Security Requirements
- Credentials stored in Keychain (NOT CoreData)
- Support for username/password authentication
- SSL/TLS validation for HTTPS

## Common Camera Brands & RTSP Formats

### Hikvision
```
rtsp://username:password@192.168.1.100:554/Streaming/Channels/101
```

### Dahua
```
rtsp://username:password@192.168.1.100:554/cam/realmonitor?channel=1&subtype=0
```

### Axis
```
rtsp://username:password@192.168.1.100:554/axis-media/media.amp
```

### Reolink
```
rtsp://username:password@192.168.1.100:554/h264Preview_01_main
```

## Known Issues & Considerations

### VLCKit Platform Differences
- iOS uses `MobileVLCKit` package
- macOS uses `VLCKit` package
- Requires platform-specific view wrappers:
  - iOS: `UIViewRepresentable`
  - macOS: `NSViewRepresentable`
- Must handle conditional compilation

### ONVIF Discovery Challenges
- SOAP/XML protocol (complex)
- Requires multicast support
- Not all cameras support ONVIF
- HTTP Digest authentication required for device queries
- Fallback to port scanning needed

### Performance Considerations
- Limit concurrent streams (recommend max 16)
- Pause off-screen players in grid view
- Use hardware acceleration
- Monitor memory pressure
- Consider lower resolution for grid thumbnails

### Memory Management
- VLCMediaPlayer instances must be properly released
- Circular reference risk with player.drawable
- Clean up observers when views disappear
- CoreData context threading

## Testing Strategy

### Phase 1 Testing
- Unit tests for repositories
- CoreData CRUD operations
- Keychain service tests

### Phase 2 Testing
- ONVIF discovery with mock responses
- Port scanner with test server
- Network error handling

### Phase 3 Testing
- VLC player lifecycle
- Stream connection/disconnection
- Authentication handling

### Phase 4 Testing
- Grid layout calculations
- Multi-stream management
- Memory leak detection

### Real-World Testing
- Test with actual camera hardware
- Multiple brands (Hikvision, Dahua, Axis, Reolink)
- Different codecs (H.264, H.265)
- Different transports (TCP, UDP, multicast)
- Performance with 8+ streams

## Development Workflow

### Phase Implementation Order
1. Foundation & Dependencies (Week 1)
2. Network Discovery (Week 2)
3. VLCKit Integration & Streaming (Week 3)
4. Grid View & Multi-Stream (Week 4)
5. Cross-Platform Polish (Week 5)
6. Testing & Hardening (Week 6)

### Branch Strategy
- `main` - Production-ready code
- `develop` - Integration branch
- `feature/*` - Feature branches
- `fix/*` - Bug fix branches

### Commit Convention
- `feat(scope): description` - New features
- `fix(scope): description` - Bug fixes
- `refactor(scope): description` - Code refactoring
- `docs(scope): description` - Documentation
- `test(scope): description` - Tests
- `chore(scope): description` - Build/tooling

## Questions & Clarifications Log

### Q1: RTSP Library Choice (Resolved)
**Question**: Pure Swift or VLCKit for RTSP streaming?
**Answer**: VLCKit (user chose Option B)
**Date**: November 27, 2025

### Q2: Platform Priority (Resolved)
**Question**: Which platform to prioritize?
**Answer**: Both iOS and macOS (universal app)
**Date**: November 27, 2025

### Q3: Grid Layout (Resolved)
**Question**: Fixed or dynamic grid?
**Answer**: Dynamic grid that adapts to camera count
**Date**: November 27, 2025

### Q4: Discovery Method (Resolved)
**Question**: ONVIF only or multiple methods?
**Answer**: ONVIF + port scanning + manual entry
**Date**: November 27, 2025

### Q5: Recording Support (Resolved)
**Question**: Live streaming only or also recording?
**Answer**: Live streaming only
**Date**: November 27, 2025

### Q6: Credentials Storage (Resolved)
**Question**: How to store camera credentials?
**Answer**: Keychain Services (not CoreData)
**Date**: November 27, 2025

## Next Steps

### Immediate Tasks (Phase 1)
1. Add VLCKit dependencies via SPM
2. Modify CoreData model (remove Item, add Camera/StreamProfile)
3. Create domain models (Camera, Credentials, StreamStatus)
4. Implement KeychainService for secure password storage
5. Implement CameraRepository with protocol
6. Create basic UI (CameraListView, AddCameraView)
7. Wire up repository to UI
8. Test CRUD operations

### After Phase 1
- Implement ONVIF discovery service
- Add port scanner
- Create discovery UI
- Integrate VLCKit for streaming
- Build grid view

## Reference Links

- [GitHub Repository](https://github.com/seadogger/WatchBox)
- [VLCKit Documentation](https://code.videolan.org/videolan/VLCKit)
- [ONVIF Specification](https://www.onvif.org/specs/core/ONVIF-Core-Specification.pdf)
- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/)

## Notes

- User prefers VLCKit over pure Swift implementation for reliability
- Security is important - always use Keychain for passwords
- Cross-platform support is essential - test on both iOS and macOS
- Performance matters - hardware acceleration and smart resource management
- User experience matters - auto-discovery should be fast and reliable

---

**Last Updated**: November 27, 2025
**Status**: Phase 1 ready to begin
**Next Milestone**: VLCKit integration and CoreData model update
