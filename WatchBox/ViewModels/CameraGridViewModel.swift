//
//  CameraGridViewModel.swift
//  WatchBox
//
//  Created on November 27, 2025
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for managing the camera grid and streaming
@MainActor
final class CameraGridViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var cameras: [Camera] = []
    @Published var streamStatuses: [UUID: StreamStatus] = [:]
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showingError = false

    // MARK: - Private Properties

    private let repository: CameraRepositoryProtocol

    // MARK: - Initialization

    init(repository: CameraRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Public Methods

    /// Load all active cameras
    func loadCameras() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let allCameras = try await repository.fetchAll()
            cameras = allCameras.filter { $0.isActive }

            // Initialize stream statuses
            for camera in cameras {
                streamStatuses[camera.id] = .disconnected
            }
        } catch {
            handleError(error)
        }
    }

    /// Get password for a camera from Keychain
    func getPassword(for cameraID: UUID) -> String? {
        return try? repository.getCredentials(for: cameraID)
    }

    /// Get stream status for a camera
    func getStatus(for cameraID: UUID) -> Binding<StreamStatus> {
        Binding(
            get: { self.streamStatuses[cameraID] ?? .disconnected },
            set: { self.streamStatuses[cameraID] = $0 }
        )
    }

    /// Calculate grid columns based on camera count
    func gridColumns(for geometry: GeometryProxy) -> [GridItem] {
        let count = cameras.count
        let columns: Int

        #if os(iOS)
        // iOS layout
        if geometry.size.width > geometry.size.height {
            // Landscape
            columns = min(count, calculateOptimalColumns(count: count, maxColumns: 4))
        } else {
            // Portrait
            columns = min(count, calculateOptimalColumns(count: count, maxColumns: 2))
        }
        #elseif os(macOS)
        // macOS layout - more space available
        columns = min(count, calculateOptimalColumns(count: count, maxColumns: 6))
        #endif

        return Array(repeating: GridItem(.flexible(), spacing: 8), count: max(1, columns))
    }

    /// Start streaming for a camera
    func startStream(for cameraID: UUID) {
        streamStatuses[cameraID] = .connecting

        // TODO: Start actual VLC stream when VLCKit is integrated
        // For now, simulate connection
        Task {
            try? await Task.sleep(for: .seconds(1))
            streamStatuses[cameraID] = .connected
        }
    }

    /// Stop streaming for a camera
    func stopStream(for cameraID: UUID) {
        streamStatuses[cameraID] = .disconnected

        // TODO: Stop actual VLC stream when VLCKit is integrated
    }

    /// Stop all streams
    func stopAllStreams() {
        for cameraID in streamStatuses.keys {
            stopStream(for: cameraID)
        }
    }

    // MARK: - Private Methods

    private func handleError(_ error: Error) {
        self.error = error
        self.showingError = true
    }

    private func calculateOptimalColumns(count: Int, maxColumns: Int) -> Int {
        guard count > 0 else { return 1 }

        switch count {
        case 1:
            return 1
        case 2...4:
            return 2
        case 5...9:
            return 3
        default:
            return min(4, maxColumns)
        }
    }
}

// MARK: - Preview Mock
extension CameraGridViewModel {
    static let preview: CameraGridViewModel = {
        let viewModel = CameraGridViewModel(repository: MockCameraRepository())
        viewModel.cameras = Camera.previewCameras
        return viewModel
    }()
}
