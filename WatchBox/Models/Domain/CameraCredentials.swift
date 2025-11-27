//
//  CameraCredentials.swift
//  WatchBox
//
//  Created on November 27, 2025
//

import Foundation

/// Secure credentials for camera authentication
struct CameraCredentials: Equatable {
    let cameraID: UUID
    let username: String
    let password: String

    init(cameraID: UUID, username: String, password: String) {
        self.cameraID = cameraID
        self.username = username
        self.password = password
    }
}

/// Errors related to credential management
enum CredentialError: LocalizedError {
    case notFound
    case saveFailed
    case deleteFailed
    case invalidData
    case keychainError(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Camera credentials not found in Keychain"
        case .saveFailed:
            return "Failed to save credentials to Keychain"
        case .deleteFailed:
            return "Failed to delete credentials from Keychain"
        case .invalidData:
            return "Invalid credential data"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        }
    }
}
