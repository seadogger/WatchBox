//
//  StreamStatus.swift
//  WatchBox
//
//  Created on November 27, 2025
//

import Foundation

/// Status of a camera stream
enum StreamStatus: Equatable {
    case disconnected
    case connecting
    case connected
    case buffering
    case error(StreamError)

    var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }

    var isLoading: Bool {
        switch self {
        case .connecting, .buffering:
            return true
        default:
            return false
        }
    }
}

/// Errors that can occur during streaming
enum StreamError: LocalizedError, Equatable {
    case invalidURL
    case authenticationFailed
    case connectionTimeout
    case streamUnavailable
    case unsupportedCodec
    case networkError
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid RTSP URL"
        case .authenticationFailed:
            return "Authentication failed. Please check username and password."
        case .connectionTimeout:
            return "Connection timed out. Please check if camera is online."
        case .streamUnavailable:
            return "Stream is unavailable"
        case .unsupportedCodec:
            return "Unsupported video codec"
        case .networkError:
            return "Network error occurred"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "Check the RTSP URL format"
        case .authenticationFailed:
            return "Verify camera credentials in settings"
        case .connectionTimeout:
            return "Check camera power and network connection"
        case .streamUnavailable:
            return "Check if camera is online and RTSP is enabled"
        case .unsupportedCodec:
            return "Try a different stream profile or update camera firmware"
        case .networkError:
            return "Check your network connection"
        case .unknown:
            return "Try restarting the camera"
        }
    }
}
