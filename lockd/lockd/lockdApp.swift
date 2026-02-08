//
//  lockdApp.swift
//  lockd
//
//  Created by Aiden Ballou on 2/8/26.
//

import SwiftUI
import CoreData

@main
struct lockdApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
