//
//  AddCameraView.swift
//  WatchBox
//
//  Created on November 27, 2025
//

import SwiftUI

/// View for adding a new camera manually
struct AddCameraView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CameraManagementViewModel

    @State private var name = ""
    @State private var rtspURL = ""
    @State private var username = ""
    @State private var password = ""
    @State private var ipAddress = ""
    @State private var port = "554"
    @State private var isSaving = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Camera Information") {
                    TextField("Name", text: $name)
                        .textContentType(.name)

                    TextField("IP Address", text: $ipAddress)
                        .textContentType(.none)
                        .keyboardType(.decimalPad)

                    TextField("Port", text: $port)
                        .textContentType(.none)
                        .keyboardType(.numberPad)
                }

                Section("Authentication") {
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .autocapitalization(.none)

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }

                Section("RTSP URL") {
                    TextField("rtsp://", text: $rtspURL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()

                    if !rtspURL.isEmpty {
                        Text(rtspURL)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Text("Enter the camera details manually or use auto-discovery to find cameras on your network.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Camera")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveCamera()
                        }
                    }
                    .disabled(!isValid || isSaving)
                }
            }
            .disabled(isSaving)
            .overlay {
                if isSaving {
                    ProgressView()
                }
            }
        }
    }

    // MARK: - Private Methods

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !ipAddress.trimmingCharacters(in: .whitespaces).isEmpty &&
        !rtspURL.trimmingCharacters(in: .whitespaces).isEmpty &&
        Int(port) != nil
    }

    private func saveCamera() async {
        isSaving = true
        defer { isSaving = false }

        let camera = Camera(
            name: name.trimmingCharacters(in: .whitespaces),
            rtspURL: rtspURL.trimmingCharacters(in: .whitespaces),
            username: username.isEmpty ? nil : username.trimmingCharacters(in: .whitespaces),
            ipAddress: ipAddress.trimmingCharacters(in: .whitespaces),
            port: Int(port) ?? 554,
            gridPosition: viewModel.cameras.count
        )

        let cameraPassword = password.isEmpty ? nil : password

        await viewModel.addCamera(camera, password: cameraPassword)

        dismiss()
    }
}

// MARK: - Edit Camera View

struct EditCameraView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    let camera: Camera
    @ObservedObject var viewModel: CameraManagementViewModel

    @State private var name: String
    @State private var rtspURL: String
    @State private var username: String
    @State private var password: String
    @State private var ipAddress: String
    @State private var port: String
    @State private var isActive: Bool
    @State private var isSaving = false

    // MARK: - Initialization

    init(camera: Camera, viewModel: CameraManagementViewModel) {
        self.camera = camera
        self.viewModel = viewModel

        _name = State(initialValue: camera.name)
        _rtspURL = State(initialValue: camera.rtspURL)
        _username = State(initialValue: camera.username ?? "")
        _password = State(initialValue: viewModel.getPassword(for: camera.id) ?? "")
        _ipAddress = State(initialValue: camera.ipAddress)
        _port = State(initialValue: String(camera.port))
        _isActive = State(initialValue: camera.isActive)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Camera Information") {
                    TextField("Name", text: $name)
                        .textContentType(.name)

                    TextField("IP Address", text: $ipAddress)
                        .textContentType(.none)
                        .keyboardType(.decimalPad)

                    TextField("Port", text: $port)
                        .textContentType(.none)
                        .keyboardType(.numberPad)

                    Toggle("Active", isOn: $isActive)
                }

                Section("Authentication") {
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .autocapitalization(.none)

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }

                Section("RTSP URL") {
                    TextField("rtsp://", text: $rtspURL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }

                Section {
                    Button("Delete Camera", role: .destructive) {
                        Task {
                            await deleteCamera()
                        }
                    }
                }
            }
            .navigationTitle("Edit Camera")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveChanges()
                        }
                    }
                    .disabled(!isValid || isSaving)
                }
            }
            .disabled(isSaving)
            .overlay {
                if isSaving {
                    ProgressView()
                }
            }
        }
    }

    // MARK: - Private Methods

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !ipAddress.trimmingCharacters(in: .whitespaces).isEmpty &&
        !rtspURL.trimmingCharacters(in: .whitespaces).isEmpty &&
        Int(port) != nil
    }

    private func saveChanges() async {
        isSaving = true
        defer { isSaving = false }

        var updatedCamera = camera
        updatedCamera.name = name.trimmingCharacters(in: .whitespaces)
        updatedCamera.rtspURL = rtspURL.trimmingCharacters(in: .whitespaces)
        updatedCamera.username = username.isEmpty ? nil : username.trimmingCharacters(in: .whitespaces)
        updatedCamera.ipAddress = ipAddress.trimmingCharacters(in: .whitespaces)
        updatedCamera.port = Int(port) ?? 554
        updatedCamera.isActive = isActive

        let cameraPassword = password.isEmpty ? nil : password

        await viewModel.updateCamera(updatedCamera, password: cameraPassword)

        dismiss()
    }

    private func deleteCamera() async {
        isSaving = true
        defer { isSaving = false }

        await viewModel.deleteCamera(camera)

        dismiss()
    }
}

// MARK: - Previews

#Preview("Add Camera") {
    AddCameraView(viewModel: .preview)
}

#Preview("Edit Camera") {
    EditCameraView(camera: .preview, viewModel: .preview)
}
