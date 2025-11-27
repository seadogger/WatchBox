# Claude Rules for WatchBox Project

## Project Overview
WatchBox is a universal Swift application (iOS + macOS + visionOS) for monitoring multiple security cameras with RTSP streaming, auto-discovery, and dynamic grid layout.

## Architecture & Design Principles

### Architecture Pattern
- **MVVM + Clean Architecture + Repository Pattern**
- Views (SwiftUI) → ViewModels → Services → Repositories → Data Sources

### Key Design Principles
1. **Protocol-Oriented Programming** - Use protocols for all services and repositories
2. **Dependency Injection** - Pass dependencies to ViewModels, avoid singletons
3. **Separation of Concerns** - Clear boundaries between layers
4. **Platform Abstraction** - Shared business logic with platform-specific UI

## Code Style & Standards

### Swift Conventions
- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use Swift 6 features: async/await, actors, structured concurrency
- Prefer value types (structs) over reference types (classes) when appropriate
- Use `guard` for early returns, avoid nested conditionals

### Naming Conventions
```swift
// Classes/Structs: PascalCase
class CameraRepository {}
struct Camera {}

// Properties/Variables: camelCase
let cameraCount: Int
var isStreaming: Bool

// Protocols: Descriptive noun or adjective
protocol CameraRepositoryProtocol {}
protocol Streamable {}

// ViewModels: End with "ViewModel"
class CameraGridViewModel: ObservableObject {}

// Services: End with "Service"
class ONVIFDiscoveryService {}

// Views: End with "View"
struct CameraGridView: View {}
```

### File Organization
```
WatchBox/
├── Models/
│   ├── Domain/        # Business models (structs)
│   └── CoreData/      # NSManagedObject subclasses
├── Views/             # SwiftUI views
├── ViewModels/        # ObservableObject view models
├── Services/          # Business logic services
├── Repositories/      # Data access layer
└── Utilities/         # Helpers and extensions
```

## Technology Stack

### Required Frameworks
- **SwiftUI** - All UI must use SwiftUI (no UIKit/AppKit views except for VLC wrapper)
- **CoreData** - Camera persistence
- **Keychain Services** - Credential storage (NEVER store passwords in CoreData)
- **Network Framework** - Discovery and port scanning
- **VLCKit/MobileVLCKit** - RTSP streaming (platform-specific)

### Forbidden Patterns
- ❌ Do NOT use UIKit/AppKit for UI (except UIViewRepresentable/NSViewRepresentable for VLC)
- ❌ Do NOT store passwords in CoreData or UserDefaults
- ❌ Do NOT use singletons (use dependency injection)
- ❌ Do NOT use force unwrapping (!) except in tests
- ❌ Do NOT use stringly-typed APIs (use enums for constants)

## Platform-Specific Code

### Cross-Platform Conditionals
```swift
#if os(iOS)
import UIKit
typealias PlatformView = UIView
#elseif os(macOS)
import AppKit
typealias PlatformView = NSView
#endif
```

### VLCKit Platform Differences
- **iOS**: Use `MobileVLCKit` package
- **macOS**: Use `VLCKit` package
- **Shared**: Use common `VLCPlayerService` interface with platform-specific implementations

## Security Requirements

### Credential Storage
```swift
// ✅ CORRECT: Use Keychain
KeychainService.save(password: "secret", for: "camera-123")

// ❌ WRONG: Never store in CoreData
camera.password = "secret" // NO!
```

### RTSP URL Construction
```swift
// Handle credentials in URL
let url = "rtsp://\(username):\(password)@\(host):\(port)/\(path)"

// Validate and sanitize all inputs
func validateRTSPURL(_ url: String) -> Bool {
    // Check format, prevent injection
}
```

### Input Validation
- Validate all RTSP URLs before use
- Sanitize user inputs to prevent injection
- Validate IP addresses and port numbers
- Handle malformed discovery responses safely

## CoreData Guidelines

### Entity Design
```swift
// Camera Entity
- id: UUID (required)
- name: String (required)
- rtspURL: String (required)
- username: String (optional)
- password: String (NEVER! Use Keychain reference only)
- ipAddress: String (required)
- port: Int16 (required)
- isActive: Bool (default: true)
- gridPosition: Int16 (for ordering)
- dateAdded: Date
- lastConnected: Date (optional)

// StreamProfile Entity
- id: UUID
- name: String
- rtspURL: String
- resolution: String
- fps: Int16
- isDefault: Bool
- camera: Relationship (to-one Camera)
```

### CoreData Best Practices
- Always use `NSManagedObjectContext` on main queue for UI updates
- Use background contexts for bulk operations
- Handle merge conflicts appropriately
- Use `@FetchRequest` in SwiftUI views
- Create domain models separate from CoreData entities

## VLCKit Integration

### Player Configuration
```swift
// Always configure these options
let options = [
    "--network-caching=300",        // Low latency
    "--rtsp-tcp",                   // Force TCP if needed
    "--avcodec-hw=any",            // Hardware decoding
    "--no-audio",                   // Disable audio if not needed
]
```

### Player Lifecycle
```swift
// 1. Create media
let media = VLCMedia(url: rtspURL)

// 2. Create player
let player = VLCMediaPlayer()
player.media = media
player.drawable = videoView

// 3. Add observers
NotificationCenter.default.addObserver(...)

// 4. Play
player.play()

// 5. Always cleanup
player.stop()
player.drawable = nil
```

### Memory Management
- Release `VLCMediaPlayer` instances when cameras go off-screen
- Pause players for off-screen cameras in grid
- Limit concurrent players (max 16)
- Monitor memory pressure and reduce active streams

## Error Handling

### Error Types
```swift
enum CameraError: LocalizedError {
    case invalidURL
    case authenticationFailed
    case connectionTimeout
    case streamUnavailable
    case unsupportedCodec

    var errorDescription: String? {
        // User-friendly messages
    }
}
```

### Error Propagation
```swift
// Use Result type for synchronous operations
func fetchCameras() -> Result<[Camera], CameraError>

// Use throws for async operations
func discoverCameras() async throws -> [Camera]

// Handle errors gracefully in UI
do {
    let cameras = try await discoverCameras()
} catch {
    // Show user-friendly error
    showAlert(error.localizedDescription)
}
```

## Testing Guidelines

### Unit Tests
- Test all repositories and services
- Mock network calls and VLC players
- Test CoreData operations
- Test domain model transformations

### What to Test
```swift
// ✅ Test business logic
func testCameraRepository_AddCamera_SavesSuccessfully()
func testONVIFDiscovery_ParsesProbeMatchCorrectly()

// ✅ Test error handling
func testCameraRepository_InvalidURL_ThrowsError()

// ✅ Test transformations
func testCamera_ToDomain_MapsCorrectly()
```

## Performance Considerations

### Grid View Optimization
- Use `LazyVGrid` for efficient scrolling
- Pause off-screen video players
- Use `.onAppear` / `.onDisappear` for player lifecycle
- Cache thumbnails for faster loading

### Network Optimization
- Batch ONVIF discovery requests
- Use concurrent port scanning with limits
- Implement request timeouts
- Cancel in-flight requests when views disappear

### Video Decoding
- Enable hardware acceleration (`:avcodec-hw=any`)
- Use lower resolution streams for grid view
- Reduce network caching for lower latency
- Monitor CPU and memory usage

## Common Patterns

### ViewModel Pattern
```swift
@MainActor
class CameraGridViewModel: ObservableObject {
    @Published var cameras: [Camera] = []
    @Published var isLoading = false
    @Published var error: Error?

    private let repository: CameraRepositoryProtocol

    init(repository: CameraRepositoryProtocol) {
        self.repository = repository
    }

    func loadCameras() async {
        isLoading = true
        defer { isLoading = false }

        do {
            cameras = try await repository.fetchCameras()
        } catch {
            self.error = error
        }
    }
}
```

### Repository Pattern
```swift
protocol CameraRepositoryProtocol {
    func fetchAll() async throws -> [Camera]
    func add(_ camera: Camera) async throws
    func update(_ camera: Camera) async throws
    func delete(_ camera: Camera) async throws
}

class CameraRepository: CameraRepositoryProtocol {
    private let context: NSManagedObjectContext
    private let keychain: KeychainServiceProtocol

    init(context: NSManagedObjectContext,
         keychain: KeychainServiceProtocol) {
        self.context = context
        self.keychain = keychain
    }

    // Implementation...
}
```

### Service Pattern
```swift
protocol ONVIFDiscoveryServiceProtocol {
    func discover(on subnet: String) async throws -> [DiscoveredCamera]
}

class ONVIFDiscoveryService: ONVIFDiscoveryServiceProtocol {
    func discover(on subnet: String) async throws -> [DiscoveredCamera] {
        // Implementation using Network framework
    }
}
```

## Documentation Standards

### Code Comments
```swift
// Use doc comments for public APIs
/// Discovers ONVIF cameras on the specified subnet
/// - Parameter subnet: The subnet to scan (e.g., "192.168.1.0/24")
/// - Returns: Array of discovered cameras
/// - Throws: `DiscoveryError` if the scan fails
func discover(on subnet: String) async throws -> [DiscoveredCamera]

// Use inline comments for complex logic
// Calculate optimal grid columns based on screen width and camera count
let columns = calculateGridColumns(count: cameras.count, width: screenWidth)
```

### File Headers
```swift
//
//  CameraRepository.swift
//  WatchBox
//
//  Created on [Date]
//

import Foundation
import CoreData
```

## Git Commit Standards

### Commit Message Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code refactoring
- `docs`: Documentation changes
- `test`: Adding/updating tests
- `chore`: Build/tooling changes

### Examples
```
feat(streaming): Add VLCKit integration for RTSP playback

- Implement VLCPlayerService wrapper
- Add platform-specific view representables
- Configure hardware decoding options

Closes #123

fix(discovery): Handle ONVIF authentication errors

- Add HTTP Digest auth support
- Improve error messages
- Add retry logic for failed requests

refactor(coredata): Extract repository protocol

- Create CameraRepositoryProtocol
- Improve testability with dependency injection
- Add mock repository for tests
```

## PR Review Checklist

Before submitting a PR, ensure:
- [ ] Code follows Swift API Design Guidelines
- [ ] No force unwrapping (!) outside of tests
- [ ] Passwords stored in Keychain, not CoreData
- [ ] Platform-specific code properly isolated
- [ ] Memory leaks checked (especially VLC players)
- [ ] Error handling implemented
- [ ] Unit tests added for new functionality
- [ ] Documentation updated if needed
- [ ] No SwiftLint warnings
- [ ] Tested on both iOS and macOS

## Common Gotchas

### VLCKit Memory Leaks
```swift
// ❌ Memory leak - circular reference
player.drawable = self.view

// ✅ Proper cleanup
override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    player.stop()
    player.drawable = nil
}
```

### CoreData Threading
```swift
// ❌ Wrong - UI context on background thread
Task.detached {
    viewContext.perform { // NO!
        // Fetch cameras
    }
}

// ✅ Correct - Use proper context
let backgroundContext = persistentContainer.newBackgroundContext()
await backgroundContext.perform {
    // Fetch cameras
}
```

### RTSP URL Encoding
```swift
// ❌ Wrong - unencoded special characters
let url = "rtsp://user:p@ssw0rd!@host:554/stream"

// ✅ Correct - encode password
let encodedPassword = password.addingPercentEncoding(withAllowedCharacters: .urlPasswordAllowed)
let url = "rtsp://\(username):\(encodedPassword!)@\(host):\(port)/\(path)"
```

## Resources

- [WatchBox Implementation Plan](../IMPLEMENTATION_PLAN.md)
- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [VLCKit Documentation](https://code.videolan.org/videolan/VLCKit)
- [ONVIF Core Specification](https://www.onvif.org/specs/core/ONVIF-Core-Specification.pdf)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

## Questions?

Refer to the implementation plan or ask for clarification before implementing features that deviate from these rules.
