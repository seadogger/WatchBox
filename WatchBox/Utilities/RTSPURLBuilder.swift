//
//  RTSPURLBuilder.swift
//  WatchBox
//
//  Created on November 27, 2025
//

import Foundation

/// Utility for building RTSP URLs with embedded credentials
struct RTSPURLBuilder {

    /// Build a complete RTSP URL with credentials
    /// - Parameters:
    ///   - baseURL: The base RTSP URL (can already include credentials or not)
    ///   - username: Username for authentication
    ///   - password: Password for authentication
    /// - Returns: Complete RTSP URL with embedded credentials
    static func buildURL(baseURL: String, username: String?, password: String?) -> String {
        // If no credentials, return base URL as-is
        guard let username = username?.trimmingCharacters(in: .whitespaces),
              !username.isEmpty else {
            return baseURL
        }

        // Check if URL already contains credentials
        if baseURL.contains("@") {
            // URL already has credentials embedded, use as-is
            return baseURL
        }

        // Parse the base URL
        guard let url = URL(string: baseURL),
              let scheme = url.scheme,
              let host = url.host else {
            return baseURL
        }

        // Build credential string
        let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed) ?? username

        var credentialString = encodedUsername
        if let password = password?.trimmingCharacters(in: .whitespaces),
           !password.isEmpty {
            let encodedPassword = password.addingPercentEncoding(withAllowedCharacters: .urlPasswordAllowed) ?? password
            credentialString += ":\(encodedPassword)"
        }

        // Reconstruct URL with credentials
        var components = "\(scheme)://\(credentialString)@\(host)"

        if let port = url.port {
            components += ":\(port)"
        }

        components += url.path

        if let query = url.query {
            components += "?\(query)"
        }

        return components
    }

    /// Extract base URL without credentials
    /// - Parameter urlString: RTSP URL possibly containing credentials
    /// - Returns: URL without embedded credentials
    static func removeCredentials(from urlString: String) -> String {
        guard let url = URL(string: urlString),
              let scheme = url.scheme else {
            return urlString
        }

        var components = "\(scheme)://"

        // Use host without user info
        if let host = url.host {
            components += host
        }

        if let port = url.port {
            components += ":\(port)"
        }

        components += url.path

        if let query = url.query {
            components += "?\(query)"
        }

        return components
    }
}
