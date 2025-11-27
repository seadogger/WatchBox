//
//  CameraRepository.swift
//  WatchBox
//
//  Created on November 27, 2025
//

import Foundation
import CoreData

/// Protocol defining camera repository operations
protocol CameraRepositoryProtocol {
    func fetchAll() async throws -> [Camera]
    func fetch(byID id: UUID) async throws -> Camera?
    func add(_ camera: Camera, password: String?) async throws
    func update(_ camera: Camera, password: String?) async throws
    func delete(_ camera: Camera) async throws
    func getCredentials(for cameraID: UUID) throws -> String?
}

/// Repository for managing camera data persistence
final class CameraRepository: CameraRepositoryProtocol {

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let keychain: KeychainServiceProtocol

    // MARK: - Initialization

    init(context: NSManagedObjectContext, keychain: KeychainServiceProtocol = KeychainService()) {
        self.context = context
        self.keychain = keychain
    }

    // MARK: - Public Methods

    /// Fetch all cameras from CoreData
    /// - Returns: Array of Camera domain models
    func fetchAll() async throws -> [Camera] {
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "Camera")
            request.sortDescriptors = [NSSortDescriptor(key: "gridPosition", ascending: true)]

            let results = try self.context.fetch(request)
            return results.compactMap { self.mapToDomain($0) }
        }
    }

    /// Fetch a camera by ID
    /// - Parameter id: UUID of the camera
    /// - Returns: Camera domain model if found
    func fetch(byID id: UUID) async throws -> Camera? {
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "Camera")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            let results = try self.context.fetch(request)
            return results.first.flatMap { self.mapToDomain($0) }
        }
    }

    /// Add a new camera
    /// - Parameters:
    ///   - camera: Camera domain model to add
    ///   - password: Optional password to store in Keychain
    func add(_ camera: Camera, password: String?) async throws {
        try await context.perform {
            let entity = NSEntityDescription.entity(forEntityName: "Camera", in: self.context)!
            let cameraEntity = NSManagedObject(entity: entity, insertInto: self.context)

            self.mapToEntity(camera, entity: cameraEntity)

            try self.context.save()
        }

        // Save password to Keychain if provided
        if let password = password {
            try keychain.save(password: password, for: camera.id)
        }
    }

    /// Update an existing camera
    /// - Parameters:
    ///   - camera: Updated camera domain model
    ///   - password: Optional new password to update in Keychain
    func update(_ camera: Camera, password: String?) async throws {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "Camera")
            request.predicate = NSPredicate(format: "id == %@", camera.id as CVarArg)
            request.fetchLimit = 1

            guard let cameraEntity = try self.context.fetch(request).first else {
                throw CameraRepositoryError.notFound
            }

            self.mapToEntity(camera, entity: cameraEntity)

            try self.context.save()
        }

        // Update password in Keychain if provided
        if let password = password {
            try keychain.updatePassword(password, for: camera.id)
        }
    }

    /// Delete a camera
    /// - Parameter camera: Camera to delete
    func delete(_ camera: Camera) async throws {
        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "Camera")
            request.predicate = NSPredicate(format: "id == %@", camera.id as CVarArg)
            request.fetchLimit = 1

            guard let cameraEntity = try self.context.fetch(request).first else {
                throw CameraRepositoryError.notFound
            }

            self.context.delete(cameraEntity)
            try self.context.save()
        }

        // Delete credentials from Keychain
        try? keychain.delete(for: camera.id)
    }

    /// Get credentials for a camera
    /// - Parameter cameraID: UUID of the camera
    /// - Returns: Password if found in Keychain
    func getCredentials(for cameraID: UUID) throws -> String? {
        return try? keychain.retrieve(for: cameraID)
    }

    // MARK: - Private Helpers

    /// Map CoreData entity to domain model
    private func mapToDomain(_ entity: NSManagedObject) -> Camera? {
        guard
            let id = entity.value(forKey: "id") as? UUID,
            let name = entity.value(forKey: "name") as? String,
            let rtspURL = entity.value(forKey: "rtspURL") as? String,
            let ipAddress = entity.value(forKey: "ipAddress") as? String,
            let port = entity.value(forKey: "port") as? Int16,
            let isActive = entity.value(forKey: "isActive") as? Bool,
            let gridPosition = entity.value(forKey: "gridPosition") as? Int16,
            let dateAdded = entity.value(forKey: "dateAdded") as? Date
        else {
            return nil
        }

        return Camera(
            id: id,
            name: name,
            rtspURL: rtspURL,
            username: entity.value(forKey: "username") as? String,
            ipAddress: ipAddress,
            port: Int(port),
            manufacturer: entity.value(forKey: "manufacturer") as? String,
            model: entity.value(forKey: "model") as? String,
            isActive: isActive,
            gridPosition: Int(gridPosition),
            dateAdded: dateAdded,
            lastConnected: entity.value(forKey: "lastConnected") as? Date,
            thumbnailData: entity.value(forKey: "thumbnailData") as? Data
        )
    }

    /// Map domain model to CoreData entity
    private func mapToEntity(_ camera: Camera, entity: NSManagedObject) {
        entity.setValue(camera.id, forKey: "id")
        entity.setValue(camera.name, forKey: "name")
        entity.setValue(camera.rtspURL, forKey: "rtspURL")
        entity.setValue(camera.username, forKey: "username")
        entity.setValue(camera.ipAddress, forKey: "ipAddress")
        entity.setValue(Int16(camera.port), forKey: "port")
        entity.setValue(camera.manufacturer, forKey: "manufacturer")
        entity.setValue(camera.model, forKey: "model")
        entity.setValue(camera.isActive, forKey: "isActive")
        entity.setValue(Int16(camera.gridPosition), forKey: "gridPosition")
        entity.setValue(camera.dateAdded, forKey: "dateAdded")
        entity.setValue(camera.lastConnected, forKey: "lastConnected")
        entity.setValue(camera.thumbnailData, forKey: "thumbnailData")
    }
}

// MARK: - Repository Errors
enum CameraRepositoryError: LocalizedError {
    case notFound
    case saveFailed
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Camera not found"
        case .saveFailed:
            return "Failed to save camera"
        case .deleteFailed:
            return "Failed to delete camera"
        }
    }
}

// MARK: - Mock Repository for Testing
final class MockCameraRepository: CameraRepositoryProtocol {
    private var cameras: [Camera] = []
    private var credentials: [UUID: String] = [:]

    func fetchAll() async throws -> [Camera] {
        return cameras.sorted { $0.gridPosition < $1.gridPosition }
    }

    func fetch(byID id: UUID) async throws -> Camera? {
        return cameras.first { $0.id == id }
    }

    func add(_ camera: Camera, password: String?) async throws {
        cameras.append(camera)
        if let password = password {
            credentials[camera.id] = password
        }
    }

    func update(_ camera: Camera, password: String?) async throws {
        guard let index = cameras.firstIndex(where: { $0.id == camera.id }) else {
            throw CameraRepositoryError.notFound
        }
        cameras[index] = camera
        if let password = password {
            credentials[camera.id] = password
        }
    }

    func delete(_ camera: Camera) async throws {
        cameras.removeAll { $0.id == camera.id }
        credentials.removeValue(forKey: camera.id)
    }

    func getCredentials(for cameraID: UUID) throws -> String? {
        return credentials[cameraID]
    }
}
