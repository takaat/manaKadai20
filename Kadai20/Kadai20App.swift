//
//  Kadai20App.swift
//  Kadai20
//
//  Created by mana on 2022/01/25.
//

import SwiftUI

@main
struct Kadai20App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
