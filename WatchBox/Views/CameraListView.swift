//
//  CameraListView.swift
//  WatchBox
//
//  Created on November 27, 2025
//

import SwiftUI

/// Main view for displaying the list of cameras
struct CameraListView: View {

    // MARK: - Properties

    @StateObject private var viewModel: CameraManagementViewModel
    @State private var showingAddCamera = false
    @State private var selectedCamera: Camera?

    // MARK: - Initialization

    init(viewModel: CameraManagementViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.cameras.isEmpty {
                    ProgressView("Loading cameras...")
                } else if viewModel.cameras.isEmpty {
                    emptyState
                } else {
                    cameraList
                }
            }
            .navigationTitle("Cameras")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddCamera = true
                    } label: {
                        Label("Add Camera", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCamera) {
                AddCameraView(viewModel: viewModel)
            }
            .sheet(item: $selectedCamera) { camera in
                EditCameraView(camera: camera, viewModel: viewModel)
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
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "video.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Cameras")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add your first camera to get started")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                showingAddCamera = true
            } label: {
                Label("Add Camera", systemImage: "plus")
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
    }

    private var cameraList: some View {
        List {
            ForEach(viewModel.cameras) { camera in
                CameraRow(camera: camera)
                    .onTapGesture {
                        selectedCamera = camera
                    }
            }
            .onDelete { indexSet in
                Task {
                    for index in indexSet {
                        await viewModel.deleteCamera(viewModel.cameras[index])
                    }
                }
            }
            .onMove { source, destination in
                viewModel.reorderCameras(from: source, to: destination)
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
        .refreshable {
            await viewModel.loadCameras()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}

// MARK: - Camera Row

struct CameraRow: View {
    let camera: Camera

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail or placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)

                if let thumbnailData = camera.thumbnailData,
                   let image = loadImage(from: thumbnailData) {
                    #if os(iOS)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    #elseif os(macOS)
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    #endif
                } else {
                    Image(systemName: "video")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(camera.name)
                    .font(.headline)

                Text(camera.ipAddress)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Circle()
                        .fill(camera.isActive ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)

                    Text(camera.isActive ? "Active" : "Inactive")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    #if os(iOS)
    private func loadImage(from data: Data) -> UIImage? {
        return UIImage(data: data)
    }
    #elseif os(macOS)
    private func loadImage(from data: Data) -> NSImage? {
        return NSImage(data: data)
    }
    #endif
}

// MARK: - Previews

#Preview("Camera List - With Cameras") {
    CameraListView(viewModel: .preview)
}

#Preview("Camera List - Empty") {
    let viewModel = CameraManagementViewModel(repository: MockCameraRepository())
    return CameraListView(viewModel: viewModel)
}
