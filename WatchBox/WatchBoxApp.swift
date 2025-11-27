//
//  WatchBoxApp.swift
//  WatchBox
//
//  Created by Jason Seeliger on 11/27/25.
//

import SwiftUI
import CoreData

@main
struct WatchBoxApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            CameraListView(viewModel: createViewModel())
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }

    private func createViewModel() -> CameraManagementViewModel {
        let context = persistenceController.container.viewContext
        let keychain = KeychainService()
        let repository = CameraRepository(context: context, keychain: keychain)
        return CameraManagementViewModel(repository: repository)
    }
}
