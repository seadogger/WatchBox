//
//  StreamProfile.swift
//  WatchBox
//
//  Created on November 27, 2025
//

import Foundation

/// Domain model representing a camera stream profile (different resolutions/quality)
struct CameraStreamProfile: Identifiable, Hashable {
    let id: UUID
    var name: String
    var rtspURL: String
    var resolution: String
    var fps: Int
    var isDefault: Bool
    let cameraID: UUID

    init(
        id: UUID = UUID(),
        name: String,
        rtspURL: String,
        resolution: String,
        fps: Int = 30,
        isDefault: Bool = false,
        cameraID: UUID
    ) {
        self.id = id
        self.name = name
        self.rtspURL = rtspURL
        self.resolution = resolution
        self.fps = fps
        self.isDefault = isDefault
        self.cameraID = cameraID
    }
}

// MARK: - Preview Helpers
extension CameraStreamProfile {
    static let preview = CameraStreamProfile(
        name: "Main Stream",
        rtspURL: "rtsp://192.168.1.100:554/stream1",
        resolution: "1920x1080",
        fps: 30,
        isDefault: true,
        cameraID: UUID()
    )

    static let previewProfiles: [CameraStreamProfile] = [
        CameraStreamProfile(
            name: "Main Stream",
            rtspURL: "rtsp://192.168.1.100:554/stream1",
            resolution: "1920x1080",
            fps: 30,
            isDefault: true,
            cameraID: UUID()
        ),
        CameraStreamProfile(
            name: "Sub Stream",
            rtspURL: "rtsp://192.168.1.100:554/stream2",
            resolution: "640x480",
            fps: 15,
            isDefault: false,
            cameraID: UUID()
        )
    ]
}
