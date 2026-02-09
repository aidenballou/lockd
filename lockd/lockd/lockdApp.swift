//
//  lockdApp.swift
//  lockd
//
//  Created by Aiden Ballou on 2/8/26.
//

import SwiftUI
import CoreData
import UIKit

@main
struct lockdApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var store = AppStore()

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white
        appearance.shadowColor = UIColor(Color(hex: "#ECECEC"))
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(store)
                .environment(\.appTheme, .athleticMinimal)
        }
    }
}
