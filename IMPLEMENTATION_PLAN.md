# WatchBox Video Security Camera Streaming App - Implementation Plan

## Overview

Build a universal Swift application (iOS + macOS) for monitoring multiple security cameras with RTSP streaming, auto-discovery, and dynamic grid layout.

## Critical Technical Constraint

**AVFoundation does not natively support RTSP streaming.**

**Recommended Approach**: Use VLCKit (MobileVLCKit for iOS, VLCKit for macOS) via Swift Package Manager. VLCKit is a battle-tested Swift-friendly wrapper around libVLC that provides:
- Full RTSP/RTMP/HTTP protocol support
- All video codecs (H.264, H.265, MJPEG, MPEG-4, etc.)
- Hardware-accelerated decoding
- Proven compatibility with major camera brands
- Active maintenance and community support

This dramatically reduces complexity while providing superior codec and protocol support compared to a custom pure Swift implementation.

## Architecture

**Pattern**: MVVM + Clean Architecture + Repository Pattern

```
Views (SwiftUI) → ViewModels → Services → Repositories → Data Sources (CoreData/Network)
```

## CoreData Model Design

### Camera Entity
- `id`: UUID (primary key)
- `name`: String (user-defined, e.g., "Front Door")
- `rtspURL`: String (complete RTSP URL)
- `username`: String (optional)
- `password`: String (Keychain reference only, NOT stored in CoreData)
- `ipAddress`: String
- `port`: Int16 (default 554)
- `manufacturer`: String (optional, from ONVIF)
- `model`: String (optional)
- `isActive`: Bool
- `gridPosition`: Int16 (display order)
- `dateAdded`: Date
- `lastConnected`: Date (optional)
- `thumbnailData`: Data (optional)

### StreamProfile Entity (for multi-stream cameras)
- `id`: UUID
- `name`: String (e.g., "Main Stream", "Sub Stream")
- `rtspURL`: String
- `resolution`: String
- `fps`: Int16
- `isDefault`: Bool
- Relationship: `camera` (to-one → Camera)

**Action Required**: Modify existing `WatchBox.xcdatamodel` to remove `Item` entity and add these two entities.

## Module Structure

```
WatchBox/
├── Models/
│   ├── Domain/
│   │   ├── Camera.swift (domain model)
│   │   ├── CameraCredentials.swift
│   │   ├── StreamStatus.swift
│   │   └── DiscoveryResult.swift
│   └── CoreData/ (generated NSManagedObject subclasses)
│
├── Views/
│   ├── CameraGrid/
│   │   ├── CameraGridView.swift (main grid - LazyVGrid)
│   │   ├── CameraGridItemView.swift (single camera cell)
│   │   └── EmptyGridStateView.swift
│   ├── CameraManagement/
│   │   ├── CameraListView.swift
│   │   ├── AddCameraView.swift (manual RTSP entry)
│   │   ├── CameraDetailView.swift
│   │   └── DiscoveryCamerasView.swift (auto-discovery results)
│   ├── VideoPlayer/
│   │   ├── RTSPVideoPlayerView.swift
│   │   └── VideoPlayerControlsView.swift
│   └── Settings/
│       └── SettingsView.swift (subnet configuration)
│
├── ViewModels/
│   ├── CameraGridViewModel.swift
│   ├── CameraManagementViewModel.swift
│   ├── DiscoveryViewModel.swift
│   └── VideoPlayerViewModel.swift
│
├── Services/
│   ├── Discovery/
│   │   ├── ONVIFDiscoveryService.swift (WS-Discovery protocol)
│   │   ├── PortScannerService.swift (scan ports 554, 8554, etc.)
│   │   └── MulticastListenerService.swift
│   ├── Streaming/
│   │   ├── VLCPlayerService.swift (VLCKit wrapper)
│   │   ├── StreamManager.swift (lifecycle management)
│   │   └── RTSPConnectionTester.swift (validate RTSP URLs)
│   ├── Network/
│   │   ├── NetworkScanner.swift (subnet scanning)
│   │   └── UDPMulticastClient.swift
│   └── Storage/
│       ├── CameraRepository.swift (data access layer)
│       ├── CameraStorageService.swift
│       └── KeychainService.swift (secure password storage)
│
└── Utilities/
    └── Helpers/
        ├── GridLayoutCalculator.swift
        └── StreamHealthMonitor.swift
```

## Implementation Phases

### Phase 1: Foundation & Dependencies (Week 1)

**Goals**: Setup architecture, add VLCKit, implement data layer

1. **Add VLCKit Dependency**
   - Add VLCKit package via SPM (separate for iOS and macOS)
   - iOS: MobileVLCKit
   - macOS: VLCKit
   - Configure platform-specific targets

2. **CoreData Setup**
   - Modify `WatchBox.xcdatamodel` - add Camera and StreamProfile entities
   - Generate NSManagedObject subclasses
   - Update `Persistence.swift` if needed

3. **Domain Models**
   - Create Swift structs for Camera, Credentials, StreamStatus
   - Mapping functions between CoreData entities and domain models

4. **Repository & Security**
   - Implement `CameraRepository` with protocol
   - Implement `KeychainService` for password storage (NOT CoreData)
   - Unit tests for data operations

5. **Basic UI**
   - Create `CameraListView` (simple list of cameras)
   - Create `AddCameraView` (form with RTSP URL, username, password fields)
   - Wire up to repository
   - Test CRUD operations

**Deliverable**: VLCKit integrated, can manually add/edit/delete cameras with persistence

### Phase 2: Network Discovery (Week 2)

**Goals**: Auto-detect cameras on network

1. **ONVIF Discovery Service**
   - Implement WS-Discovery multicast (239.255.255.250:3702)
   - Build SOAP Probe message (XML)
   - Parse ProbeMatch responses using XMLParser
   - Extract device XAddr and query GetCapabilities for RTSP URLs
   - Handle HTTP Digest authentication

2. **Port Scanner Service**
   - Parse subnet notation (e.g., "192.168.1.0/24")
   - Generate IP range
   - Test common RTSP ports: [554, 8554, 88, 7447, 5000]
   - Use NWConnection for TCP connectivity test
   - Send RTSP OPTIONS to validate

3. **Multicast Listener**
   - Listen for multicast announcements
   - Parse discovery messages

4. **Discovery UI**
   - Create `DiscoveryCamerasView` showing found cameras
   - Allow user to select and add to camera list
   - Handle duplicates
   - Show discovery progress

**Deliverable**: Auto-discover ONVIF cameras and RTSP streams on subnet

### Phase 3: VLCKit Integration & Streaming (Week 3)

**Goals**: Display live video from RTSP cameras using VLCKit

1. **VLCPlayerService Implementation**
   - `VLCPlayerService.swift`:
     - Create VLCMediaPlayer instance
     - Configure player options (network caching, hardware decoding)
     - Handle authentication (embed username:password in RTSP URL)
     - Set drawable view for rendering
     - Implement play/pause/stop controls

2. **Video Display View**
   - `RTSPVideoPlayerView.swift`:
     - SwiftUI wrapper for VLCKit player
     - Platform-specific view implementation:
       - iOS: UIViewRepresentable wrapping UIView
       - macOS: NSViewRepresentable wrapping NSView
     - Handle player lifecycle
     - Display loading/error states

3. **Connection Testing**
   - `RTSPConnectionTester.swift`:
     - Validate RTSP URL format
     - Test connection before adding to grid
     - Quick OPTIONS request to verify endpoint
     - Return connection status and error messages

4. **Stream Manager**
   - `StreamManager.swift`:
     - Manage VLCMediaPlayer instances for each camera
     - Connection lifecycle (connect, reconnect, disconnect)
     - Health monitoring (detect frozen streams via VLC callbacks)
     - Resource cleanup and memory management
     - Implement reconnection logic for failed streams

5. **ViewModel Integration**
   - `VideoPlayerViewModel.swift`:
     - Bridge between View and VLCPlayerService
     - Handle player state (playing, paused, stopped, error)
     - Process VLC callbacks and notifications
     - Expose stream status to UI

**Deliverable**: Single camera stream displaying live video using VLCKit

### Phase 4: Grid View & Multi-Stream (Week 4)

**Goals**: Display multiple cameras simultaneously

1. **Dynamic Grid Layout**
   - `CameraGridView.swift`:
     - Use SwiftUI `LazyVGrid` with `GridItem(.adaptive(...))`
     - Calculate optimal columns based on:
       - Screen width (iPhone/iPad/Mac)
       - Number of cameras (1, 2-4, 5-9, 10-16, etc.)
       - Orientation (portrait/landscape)
     - Spacing and padding

2. **Multi-Stream Management**
   - Limit concurrent active streams (e.g., max 16)
   - Pause off-screen streams (use `.onAppear`/`.onDisappear`)
   - Priority queue for decoding resources
   - Memory pressure handling

3. **Performance Optimization**
   - Use VideoToolbox hardware acceleration
   - Reduce resolution for thumbnail views if needed
   - Implement lazy loading for grid cells
   - Monitor CPU and memory usage

4. **Grid Interactions**
   - Tap to expand camera to full screen
   - Drag-to-reorder cameras (update `gridPosition`)
   - Pull-to-refresh for reconnecting

**Deliverable**: Grid view with multiple live camera streams

### Phase 5: Cross-Platform Polish (Week 5)

**Goals**: Platform-specific features and UX refinement

1. **macOS-Specific**
   - Menu bar (File, View, Camera, Window)
   - Window management (resizable grid)
   - Keyboard shortcuts (Cmd+N for new camera, etc.)
   - Right-click context menus
   - Drag-and-drop for reordering

2. **iOS-Specific**
   - Touch gestures (pinch to zoom, swipe between cameras)
   - Orientation handling (portrait/landscape grid adjustment)
   - Background behavior (pause streams when backgrounded)
   - Local notifications for connection failures

3. **Settings View**
   - Subnet configuration for discovery
   - Default credentials
   - Performance settings (max concurrent streams)
   - Theme preferences

4. **UI Polish**
   - Loading states (skeleton views, spinners)
   - Error states (connection failed, authentication error)
   - Empty states (no cameras yet)
   - Dark mode support
   - Accessibility labels

**Deliverable**: Fully functional cross-platform app

### Phase 6: Testing & Hardening (Week 6)

**Goals**: Ensure production reliability

1. **Unit Tests**
   - Repository tests (CoreData CRUD)
   - RTSP parser tests
   - SDP parser tests
   - Grid layout calculator tests

2. **Integration Tests**
   - ONVIF discovery with mock responses
   - Port scanner with local test server
   - Stream lifecycle

3. **UI Tests**
   - Add camera flow
   - Discovery flow
   - Grid interaction

4. **Error Handling**
   - Network failures (timeout, unreachable)
   - Authentication failures (401, 403)
   - Unsupported codec
   - Stream timeout/freeze detection
   - Invalid RTSP URL

5. **Real-World Testing**
   - Test with multiple camera brands (Hikvision, Dahua, Axis, etc.)
   - Test different codecs (H.264, H.265)
   - Test different transport (TCP, UDP, multicast)
   - Performance testing (8+ streams)

**Deliverable**: Production-ready application

## Technical Implementation Details

### VLCKit RTSP Streaming Flow

```
1. User enters RTSP URL: rtsp://192.168.1.100:554/stream1
   Username: admin
   Password: password123

2. VLCPlayerService creates media:
   - Build authenticated URL: rtsp://admin:password123@192.168.1.100:554/stream1
   - Create VLCMedia with URL
   - Configure options:
     - :network-caching=300 (ms)
     - :rtsp-tcp (force TCP if needed)
     - :avcodec-hw=any (hardware decoding)

3. Create VLCMediaPlayer:
   - Set media
   - Set drawable (UIView/NSView)
   - Add state change observers
   - Call play()

4. VLCKit handles internally:
   - RTSP protocol negotiation
   - RTP packet reception
   - Video decoding (all codecs)
   - Audio decoding (if present)
   - Rendering to view

5. App monitors via callbacks:
   - VLCMediaPlayerStateOpening
   - VLCMediaPlayerStatePlaying
   - VLCMediaPlayerStateError
   - Update UI accordingly
```

### ONVIF Discovery Flow

```
1. User taps "Discover Cameras"

2. ONVIFDiscoveryService:
   - Create UDP socket to 239.255.255.250:3702
   - Send WS-Discovery Probe (SOAP/XML)
   - Listen for ProbeMatch responses (timeout 5s)

3. Parse responses:
   - Extract device XAddr (endpoint URL)
   - For each device: HTTP GET to XAddr/onvif/device_service
   - Call GetCapabilities → Extract RTSP stream URLs

4. Display in DiscoveryCamerasView:
   - Show manufacturer, model, IP, RTSP URL
   - User selects cameras to add

5. Save to CoreData via CameraRepository
```

### Grid Layout Algorithm

```swift
func calculateGridColumns(cameraCount: Int, screenWidth: CGFloat) -> [GridItem] {
    let minCellWidth: CGFloat = 200
    let maxCellWidth: CGFloat = 500
    let idealCellWidth: CGFloat = 300

    // How many columns can fit?
    let maxColumns = max(1, Int(screenWidth / minCellWidth))

    // What's optimal for this camera count?
    let optimalColumns: Int
    switch cameraCount {
    case 1: optimalColumns = 1
    case 2...4: optimalColumns = 2
    case 5...9: optimalColumns = 3
    case 10...16: optimalColumns = 4
    default: optimalColumns = 5
    }

    let columns = min(maxColumns, optimalColumns)

    return Array(repeating: GridItem(.adaptive(minimum: minCellWidth,
                                               maximum: maxCellWidth),
                                     spacing: 8),
                 count: columns)
}
```

## Key Technical Challenges & Solutions

### Challenge 1: RTSP Streaming
**Problem**: AVFoundation doesn't support RTSP natively
**Solution**:
- Use VLCKit (MobileVLCKit/VLCKit) for proven RTSP support
- VLCKit handles all protocols and codecs internally
- Hardware acceleration via VLC's avcodec-hw option
- Simpler implementation than custom RTSP client

### Challenge 2: Multiple Simultaneous Streams
**Problem**: Decoding many streams is CPU/memory intensive
**Solution**:
- VLCKit provides hardware acceleration automatically
- Pause off-screen VLCMediaPlayer instances
- Limit max concurrent streams (16)
- Monitor VLC player state and pause based on visibility
- Release players for cameras not in view

### Challenge 3: Platform-Specific VLCKit Integration
**Problem**: Different VLCKit packages for iOS and macOS
**Solution**:
- Use conditional SPM dependencies:
  - iOS: MobileVLCKit
  - macOS: VLCKit
- Platform-specific view wrappers:
  - iOS: UIViewRepresentable
  - macOS: NSViewRepresentable
- Shared VLCPlayerService with platform abstraction

### Challenge 4: ONVIF Discovery Complexity
**Problem**: SOAP/XML protocol with authentication
**Solution**:
- Implement WS-Discovery multicast for initial discovery
- Use XMLParser for SOAP response parsing
- Implement HTTP Digest auth for device queries
- Fallback to port scanning if ONVIF fails
- Always allow manual entry as primary method

### Challenge 5: Cross-Platform UI
**Problem**: Different interaction patterns on iOS vs macOS
**Solution**:
- Use `#if os(macOS)` / `#if os(iOS)` for platform-specific code
- Different toolbar/menu placement
- Adapt gestures (touch vs mouse)
- Test regularly on both platforms

## Technology Stack

**Apple Frameworks + VLCKit**:

- **SwiftUI**: UI framework (LazyVGrid, NavigationView)
- **CoreData**: Camera persistence
- **Security**: Keychain Services for password storage
- **Network**: Discovery and port scanning (NWConnection, NWListener)
- **Foundation**: URLSession for ONVIF HTTP requests
- **Swift Concurrency**: async/await, Task, AsyncStream
- **VLCKit**: RTSP streaming and video decoding (Third-party dependency)
  - iOS: MobileVLCKit (via SPM)
  - macOS: VLCKit (via SPM)
  - Handles RTSP, RTP, codecs, and rendering internally

## Critical Files to Create/Modify

### Must Modify
1. `WatchBox/WatchBox.xcdatamodeld/WatchBox.xcdatamodel/contents` - Add Camera and StreamProfile entities
2. `WatchBox.xcodeproj/project.pbxproj` - Add VLCKit package dependencies

### Core Components to Create
3. `WatchBox/Services/Streaming/VLCPlayerService.swift` - VLCKit wrapper (replaces custom RTSP client)
4. `WatchBox/Services/Streaming/StreamManager.swift` - Manage multiple VLC player instances
5. `WatchBox/Views/VideoPlayer/RTSPVideoPlayerView.swift` - Platform-specific VLC view wrapper
6. `WatchBox/Views/CameraGrid/CameraGridView.swift` - Main grid UI with LazyVGrid
7. `WatchBox/Services/Discovery/ONVIFDiscoveryService.swift` - WS-Discovery implementation
8. `WatchBox/Services/Discovery/PortScannerService.swift` - RTSP port scanning
9. `WatchBox/Services/Storage/CameraRepository.swift` - CoreData access layer
10. `WatchBox/Services/Storage/KeychainService.swift` - Secure credential storage

## Security Considerations

1. **Password Storage**: Use Keychain Services, NOT CoreData
2. **RTSP Authentication**: Support Basic and Digest auth
3. **Network Security**: Validate SSL certificates for HTTPS ONVIF requests
4. **Input Validation**: Sanitize user-entered URLs and credentials
5. **Memory Safety**: Proper cleanup of video buffers and decode sessions

## Development Best Practices

- **Protocol-Oriented**: Use protocols for testability
- **Dependency Injection**: Pass dependencies to ViewModels
- **Error Handling**: Comprehensive error types with user-friendly messages
- **Logging**: Use OSLog for debugging RTSP/RTP issues
- **Documentation**: Document RTSP protocol handling thoroughly
- **Testing**: Unit tests for parsers, integration tests for discovery

## Success Criteria

✅ Can manually add cameras with RTSP URL + credentials
✅ Can auto-discover ONVIF cameras on subnet
✅ Can display live video from RTSP streams
✅ Grid layout adapts to number of cameras dynamically
✅ Works on both iOS and macOS
✅ Credentials stored securely in Keychain
✅ Handles network errors gracefully
✅ Supports multiple simultaneous streams (8+)
✅ Performance is smooth with hardware decoding
