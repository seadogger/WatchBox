//
//  CameraGridView.swift
//  WatchBox
//
//  Created on November 27, 2025
//

import SwiftUI

/// Main grid view for displaying multiple camera streams
struct CameraGridView: View {

    // MARK: - Properties

    @StateObject private var viewModel: CameraGridViewModel
    @State private var selectedCamera: Camera?
    @State private var showingSettings = false

    // MARK: - Initialization

    init(viewModel: CameraGridViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                Group {
                    if viewModel.isLoading && viewModel.cameras.isEmpty {
                        ProgressView("Loading cameras...")
                    } else if viewModel.cameras.isEmpty {
                        emptyState
                    } else {
                        cameraGrid(geometry: geometry)
                    }
                }
            }
            .navigationTitle("WatchBox")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }

                #if os(iOS)
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        Task {
                            await viewModel.loadCameras()
                        }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingSettings) {
                CameraListView(viewModel: CameraManagementViewModel(
                    repository: MockCameraRepository()
                ))
            }
            .sheet(item: $selectedCamera) { camera in
                FullscreenCameraView(camera: camera, viewModel: viewModel)
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") {
                    viewModel.showingError = false
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
            .task {
                await viewModel.loadCameras()
            }
            .onDisappear {
                viewModel.stopAllStreams()
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "video.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Active Cameras")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add cameras in settings to start monitoring")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingSettings = true
            } label: {
                Label("Open Settings", systemImage: "gear")
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
    }

    private func cameraGrid(geometry: GeometryProxy) -> some View {
        ScrollView {
            LazyVGrid(columns: viewModel.gridColumns(for: geometry), spacing: 8) {
                ForEach(viewModel.cameras) { camera in
                    CameraGridCell(
                        camera: camera,
                        status: viewModel.getStatus(for: camera.id)
                    )
                    .aspectRatio(16/9, contentMode: .fit)
                    .onTapGesture {
                        selectedCamera = camera
                    }
                    .onAppear {
                        viewModel.startStream(for: camera.id)
                    }
                    .onDisappear {
                        viewModel.stopStream(for: camera.id)
                    }
                }
            }
            .padding(8)
        }
    }
}

// MARK: - Camera Grid Cell

struct CameraGridCell: View {
    let camera: Camera
    @Binding var status: StreamStatus

    var body: some View {
        MockVideoPlayerView(camera: camera, status: $status)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Fullscreen Camera View

struct FullscreenCameraView: View {
    let camera: Camera
    @ObservedObject var viewModel: CameraGridViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            MockVideoPlayerView(
                camera: camera,
                status: viewModel.getStatus(for: camera.id)
            )
            .ignoresSafeArea()
            .navigationTitle(camera.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Grid - 4 Cameras") {
    CameraGridView(viewModel: .preview)
}

#Preview("Grid - Empty") {
    let viewModel = CameraGridViewModel(repository: MockCameraRepository())
    return CameraGridView(viewModel: viewModel)
}
