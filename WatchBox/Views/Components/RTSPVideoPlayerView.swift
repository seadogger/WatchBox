//
//  RTSPVideoPlayerView.swift
//  WatchBox
//
//  Created on November 27, 2025
//
//  Real RTSP video player using VLCKit
//  NOTE: Requires VLCKit to be installed via Swift Package Manager
//

import SwiftUI

// VLCKit imports - commented out until package is added
// #if os(iOS)
// import MobileVLCKit
// #elseif os(macOS)
// import VLCKit
// #endif

/// Real RTSP video player view
struct RTSPVideoPlayerView: View {
    let camera: Camera
    let password: String?
    @Binding var status: StreamStatus

    var body: some View {
        // Use native AVFoundation player (works with most RTSP streams)
        NativeRTSPPlayerView(camera: camera, password: password, status: $status)
    }
}

/// Placeholder that shows what the real implementation will do
struct VLCPlayerPlaceholder: View {
    let camera: Camera
    let password: String?
    @Binding var status: StreamStatus

    @State private var isAnimating = false
    @State private var constructedURL: String = ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, .blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 16) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.white.opacity(0.8))
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)

                VStack(spacing: 8) {
                    Text("Ready to Stream")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(camera.name)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))

                    Text(camera.ipAddress)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))

                    // Show constructed RTSP URL
                    if !constructedURL.isEmpty {
                        VStack(spacing: 4) {
                            Text("Stream URL:")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))

                            Text(sanitizedURLForDisplay(constructedURL))
                                .font(.caption2)
                                .foregroundStyle(.green.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                        .padding(.top, 4)
                    }

                    // Status
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.orange)
                            .frame(width: 8, height: 8)

                        Text("VLCKit Required")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.3))
                    .clipShape(Capsule())

                    Text("Install VLCKit to enable streaming")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.top, 4)
                }
            }
            .padding()
        }
        .onAppear {
            isAnimating = true
            // Build the actual RTSP URL that will be used
            constructedURL = RTSPURLBuilder.buildURL(
                baseURL: camera.rtspURL,
                username: camera.username,
                password: password
            )
            status = .connecting
        }
    }

    /// Sanitize URL for display (hide password)
    private func sanitizedURLForDisplay(_ urlString: String) -> String {
        guard let url = URL(string: urlString),
              let user = url.user else {
            return urlString
        }

        // Show username but hide password
        if url.password != nil {
            return urlString.replacingOccurrences(of: ":\(url.password!)", with: ":****")
        }

        return urlString
    }
}

// MARK: - Real VLC Implementation (will be enabled once VLCKit is installed)

/*

 Once VLCKit is installed, uncomment this code and use VLCPlayerView instead:

#if os(iOS)
import MobileVLCKit

struct VLCPlayerView: UIViewRepresentable {
    let camera: Camera
    let password: String?
    @Binding var status: StreamStatus

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black

        let player = VLCMediaPlayer()
        let rtspURL = RTSPURLBuilder.buildURL(
            baseURL: camera.rtspURL,
            username: camera.username,
            password: password
        )

        guard let url = URL(string: rtspURL) else {
            status = .error(.invalidURL)
            return view
        }

        let media = VLCMedia(url: url)

        // Configure for low latency RTSP
        media.addOption("--network-caching=300")
        media.addOption("--rtsp-tcp")
        media.addOption("--avcodec-hw=any")
        media.addOption("--no-audio")

        player.media = media
        player.drawable = view
        player.delegate = context.coordinator

        context.coordinator.player = player
        player.play()

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(status: $status)
    }

    class Coordinator: NSObject, VLCMediaPlayerDelegate {
        @Binding var status: StreamStatus
        var player: VLCMediaPlayer?

        init(status: Binding<StreamStatus>) {
            _status = status
        }

        func mediaPlayerStateChanged(_ notification: Notification) {
            guard let player = player else { return }

            switch player.state {
            case .opening:
                status = .connecting
            case .buffering:
                status = .buffering
            case .playing:
                status = .connected
            case .error:
                status = .error(.streamUnavailable)
            case .stopped, .ended:
                status = .disconnected
            default:
                break
            }
        }
    }
}
#elseif os(macOS)
import VLCKit

struct VLCPlayerView: NSViewRepresentable {
    let camera: Camera
    let password: String?
    @Binding var status: StreamStatus

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor

        let player = VLCMediaPlayer()
        let rtspURL = RTSPURLBuilder.buildURL(
            baseURL: camera.rtspURL,
            username: camera.username,
            password: password
        )

        guard let url = URL(string: rtspURL) else {
            status = .error(.invalidURL)
            return view
        }

        let media = VLCMedia(url: url)

        media.addOption("--network-caching=300")
        media.addOption("--rtsp-tcp")
        media.addOption("--avcodec-hw=any")
        media.addOption("--no-audio")

        player.media = media
        player.drawable = view
        player.delegate = context.coordinator

        context.coordinator.player = player
        player.play()

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(status: $status)
    }

    class Coordinator: NSObject, VLCMediaPlayerDelegate {
        @Binding var status: StreamStatus
        var player: VLCMediaPlayer?

        init(status: Binding<StreamStatus>) {
            _status = status
        }

        func mediaPlayerStateChanged(_ notification: Notification) {
            guard let player = player else { return }

            switch player.state {
            case .opening:
                status = .connecting
            case .buffering:
                status = .buffering
            case .playing:
                status = .connected
            case .error:
                status = .error(.streamUnavailable)
            case .stopped, .ended:
                status = .disconnected
            default:
                break
            }
        }
    }
}
#endif

*/

#Preview {
    RTSPVideoPlayerView(
        camera: .preview,
        password: "testpass",
        status: .constant(.connecting)
    )
    .frame(width: 320, height: 240)
}
