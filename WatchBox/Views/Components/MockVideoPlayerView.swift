//
//  MockVideoPlayerView.swift
//  WatchBox
//
//  Created on November 27, 2025
//
//  This is a placeholder view until VLCKit is integrated
//

import SwiftUI

/// Mock video player view - displays placeholder until VLCKit is integrated
struct MockVideoPlayerView: View {
    let camera: Camera
    @Binding var status: StreamStatus

    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.black, .gray.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 12) {
                // Camera icon with animation
                Image(systemName: "video.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.white.opacity(0.8))
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)

                // Camera info
                VStack(spacing: 4) {
                    Text(camera.name)
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(camera.ipAddress)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))

                    // Status badge
                    statusBadge
                }
            }
            .padding()
        }
        .onAppear {
            isAnimating = true
            // Simulate connecting
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                status = .connecting
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                status = .connected
            }
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.black.opacity(0.3))
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
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Live"
        case .buffering:
            return "Buffering..."
        case .error(let error):
            return error.localizedDescription
        }
    }
}

#Preview {
    MockVideoPlayerView(
        camera: .preview,
        status: .constant(.connected)
    )
    .frame(width: 320, height: 240)
}
