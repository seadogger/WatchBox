//
//  NativeRTSPPlayerView.swift
//  WatchBox
//
//  Created on November 27, 2025
//
//  Native RTSP player using AVFoundation (no external dependencies!)
//

import SwiftUI
import AVFoundation
import AVKit
import Combine

/// Native RTSP video player using AVFoundation
struct NativeRTSPPlayerView: View {
    let camera: Camera
    let password: String?
    @Binding var status: StreamStatus

    @State private var player: AVPlayer?
    @State private var isReady = false

    private let rtspURL: String

    init(camera: Camera, password: String?, status: Binding<StreamStatus>) {
        self.camera = camera
        self.password = password
        self._status = status

        self.rtspURL = RTSPURLBuilder.buildURL(
            baseURL: camera.rtspURL,
            username: camera.username,
            password: password
        )
    }

    var body: some View {
        ZStack {
            Color.black

            if let player = player {
                VideoPlayer(player: player)
                    .disabled(true) // Disable native controls
            }

            // Overlay camera info
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(camera.name)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .shadow(radius: 2)

                        Text(camera.ipAddress)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.8))
                            .shadow(radius: 2)
                    }

                    Spacer()

                    statusBadge
                }
                .padding(8)

                Spacer()
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            cleanupPlayer()
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)

            Text(statusText)
                .font(.caption2)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.black.opacity(0.6))
        .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch status {
        case .disconnected:
            return .red
        case .connecting, .buffering:
            return .orange
        case .connected:
            return .green
        case .error:
            return .red
        }
    }

    private var statusText: String {
        switch status {
        case .disconnected:
            return "Offline"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Live"
        case .buffering:
            return "Buffering"
        case .error:
            return "Error"
        }
    }

    private func setupPlayer() {
        guard let url = URL(string: rtspURL) else {
            status = .error(.invalidURL)
            return
        }

        status = .connecting

        let playerItem = AVPlayerItem(url: url)
        let avPlayer = AVPlayer(playerItem: playerItem)

        // Configure for live streaming
        avPlayer.automaticallyWaitsToMinimizeStalling = false
        avPlayer.play()

        // Observe player status
        Task {
            for await status in playerItem.publisher(for: \.status).values {
                await MainActor.run {
                    switch status {
                    case .readyToPlay:
                        self.status = .connected
                        isReady = true
                    case .failed:
                        self.status = .error(.streamUnavailable)
                    case .unknown:
                        self.status = .connecting
                    @unknown default:
                        break
                    }
                }
            }
        }

        player = avPlayer
    }

    private func cleanupPlayer() {
        player?.pause()
        player = nil
        status = .disconnected
    }
}

#Preview {
    NativeRTSPPlayerView(
        camera: .preview,
        password: "testpass",
        status: .constant(.connected)
    )
    .frame(width: 320, height: 240)
}
