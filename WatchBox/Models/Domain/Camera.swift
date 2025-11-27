//
//  Camera.swift
//  WatchBox
//
//  Created on November 27, 2025
//

import Foundation

/// Domain model representing a security camera
struct Camera: Identifiable, Hashable {
    let id: UUID
    var name: String
    var rtspURL: String
    var username: String?
    var ipAddress: String
    var port: Int
    var manufacturer: String?
    var model: String?
    var isActive: Bool
    var gridPosition: Int
    let dateAdded: Date
    var lastConnected: Date?
    var thumbnailData: Data?

    /// Initialize a new camera
    init(
        id: UUID = UUID(),
        name: String,
        rtspURL: String,
        username: String? = nil,
        ipAddress: String,
        port: Int = 554,
        manufacturer: String? = nil,
        model: String? = nil,
        isActive: Bool = true,
        gridPosition: Int = 0,
        dateAdded: Date = Date(),
        lastConnected: Date? = nil,
        thumbnailData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.rtspURL = rtspURL
        self.username = username
        self.ipAddress = ipAddress
        self.port = port
        self.manufacturer = manufacturer
        self.model = model
        self.isActive = isActive
        self.gridPosition = gridPosition
        self.dateAdded = dateAdded
        self.lastConnected = lastConnected
        self.thumbnailData = thumbnailData
    }
}

// MARK: - Preview Helpers
extension Camera {
    /// Sample camera for previews and testing
    static let preview = Camera(
        name: "Front Door",
        rtspURL: "rtsp://192.168.1.100:554/stream1",
        username: "admin",
        ipAddress: "192.168.1.100",
        port: 554,
        manufacturer: "Hikvision",
        model: "DS-2CD2142FWD-I"
    )

    /// Multiple sample cameras for grid preview
    static let previewCameras: [Camera] = [
        Camera(
            name: "Front Door",
            rtspURL: "rtsp://192.168.1.100:554/stream1",
            username: "admin",
            ipAddress: "192.168.1.100",
            gridPosition: 0
        ),
        Camera(
            name: "Back Yard",
            rtspURL: "rtsp://192.168.1.101:554/stream1",
            username: "admin",
            ipAddress: "192.168.1.101",
            gridPosition: 1
        ),
        Camera(
            name: "Garage",
            rtspURL: "rtsp://192.168.1.102:554/stream1",
            username: "admin",
            ipAddress: "192.168.1.102",
            gridPosition: 2
        ),
        Camera(
            name: "Driveway",
            rtspURL: "rtsp://192.168.1.103:554/stream1",
            username: "admin",
            ipAddress: "192.168.1.103",
            gridPosition: 3
        )
    ]
}
