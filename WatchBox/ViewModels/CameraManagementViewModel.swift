//
//  CameraManagementViewModel.swift
//  WatchBox
//
//  Created on November 27, 2025
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for managing camera list and CRUD operations
@MainActor
final class CameraManagementViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var cameras: [Camera] = []
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

    /// Load all cameras from the repository
    func loadCameras() async {
        isLoading = true
        defer { isLoading = false }

        do {
            cameras = try await repository.fetchAll()
        } catch {
            handleError(error)
        }
    }

    /// Add a new camera
    /// - Parameters:
    ///   - camera: Camera to add
    ///   - password: Optional password for authentication
    func addCamera(_ camera: Camera, password: String?) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await repository.add(camera, password: password)
            await loadCameras()
        } catch {
            handleError(error)
        }
    }

    /// Update an existing camera
    /// - Parameters:
    ///   - camera: Updated camera
    ///   - password: Optional new password
    func updateCamera(_ camera: Camera, password: String?) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await repository.update(camera, password: password)
            await loadCameras()
        } catch {
            handleError(error)
        }
    }

    /// Delete a camera
    /// - Parameter camera: Camera to delete
    func deleteCamera(_ camera: Camera) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await repository.delete(camera)
            await loadCameras()
        } catch {
            handleError(error)
        }
    }

    /// Get credentials for a camera
    /// - Parameter cameraID: UUID of the camera
    /// - Returns: Password if found
    func getPassword(for cameraID: UUID) -> String? {
        return try? repository.getCredentials(for: cameraID)
    }

    /// Reorder cameras in the grid
    /// - Parameters:
    ///   - source: Source index set
    ///   - destination: Destination index
    func reorderCameras(from source: IndexSet, to destination: Int) {
        var updatedCameras = cameras
        updatedCameras.move(fromOffsets: source, toOffset: destination)

        // Update grid positions
        for (index, camera) in updatedCameras.enumerated() {
            var updatedCamera = camera
            updatedCamera.gridPosition = index
            updatedCameras[index] = updatedCamera

            Task {
                try? await repository.update(updatedCamera, password: nil)
            }
        }

        cameras = updatedCameras
    }

    // MARK: - Private Methods

    private func handleError(_ error: Error) {
        self.error = error
        self.showingError = true
    }
}

// MARK: - Preview Mock
extension CameraManagementViewModel {
    static let preview: CameraManagementViewModel = {
        let viewModel = CameraManagementViewModel(repository: MockCameraRepository())
        viewModel.cameras = Camera.previewCameras
        return viewModel
    }()
}
