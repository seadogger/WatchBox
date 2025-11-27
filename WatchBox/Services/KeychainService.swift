//
//  KeychainService.swift
//  WatchBox
//
//  Created on November 27, 2025
//

import Foundation
import Security

/// Protocol for Keychain operations
protocol KeychainServiceProtocol {
    func save(password: String, for cameraID: UUID) throws
    func retrieve(for cameraID: UUID) throws -> String
    func delete(for cameraID: UUID) throws
    func updatePassword(_ password: String, for cameraID: UUID) throws
}

/// Service for securely storing and retrieving camera credentials in Keychain
final class KeychainService: KeychainServiceProtocol {

    // MARK: - Properties

    private let service = "com.seadogger.WatchBox.cameras"

    // MARK: - Public Methods

    /// Save a password for a camera to the Keychain
    /// - Parameters:
    ///   - password: The password to save
    ///   - cameraID: The unique identifier for the camera
    /// - Throws: CredentialError if the save operation fails
    func save(password: String, for cameraID: UUID) throws {
        guard let passwordData = password.data(using: .utf8) else {
            throw CredentialError.invalidData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: cameraID.uuidString,
            kSecValueData as String: passwordData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        // Delete any existing item first
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw CredentialError.keychainError(status: status)
        }
    }

    /// Retrieve a password for a camera from the Keychain
    /// - Parameter cameraID: The unique identifier for the camera
    /// - Returns: The password for the camera
    /// - Throws: CredentialError if the password is not found or cannot be retrieved
    func retrieve(for cameraID: UUID) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: cameraID.uuidString,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw CredentialError.notFound
            }
            throw CredentialError.keychainError(status: status)
        }

        guard let passwordData = result as? Data,
              let password = String(data: passwordData, encoding: .utf8) else {
            throw CredentialError.invalidData
        }

        return password
    }

    /// Delete a password for a camera from the Keychain
    /// - Parameter cameraID: The unique identifier for the camera
    /// - Throws: CredentialError if the delete operation fails
    func delete(for cameraID: UUID) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: cameraID.uuidString
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw CredentialError.keychainError(status: status)
        }
    }

    /// Update a password for a camera in the Keychain
    /// - Parameters:
    ///   - password: The new password
    ///   - cameraID: The unique identifier for the camera
    /// - Throws: CredentialError if the update operation fails
    func updatePassword(_ password: String, for cameraID: UUID) throws {
        // Delete and re-save to update
        try? delete(for: cameraID)
        try save(password: password, for: cameraID)
    }
}

// MARK: - Mock for Testing
final class MockKeychainService: KeychainServiceProtocol {
    private var storage: [UUID: String] = [:]

    func save(password: String, for cameraID: UUID) throws {
        storage[cameraID] = password
    }

    func retrieve(for cameraID: UUID) throws -> String {
        guard let password = storage[cameraID] else {
            throw CredentialError.notFound
        }
        return password
    }

    func delete(for cameraID: UUID) throws {
        storage.removeValue(forKey: cameraID)
    }

    func updatePassword(_ password: String, for cameraID: UUID) throws {
        storage[cameraID] = password
    }
}
