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
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
