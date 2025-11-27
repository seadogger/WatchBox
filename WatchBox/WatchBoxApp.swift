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
            CameraGridView(viewModel: createGridViewModel())
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }

    private func createGridViewModel() -> CameraGridViewModel {
        let context = persistenceController.container.viewContext
        let keychain = KeychainService()
        let repository = CameraRepository(context: context, keychain: keychain)
        return CameraGridViewModel(repository: repository)
    }
}
