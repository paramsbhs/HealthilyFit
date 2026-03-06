//
//  FormRecorderApp.swift
//  FormRecorder
//
//  Created by Param Grewal on 2026-02-24.
//

import SwiftUI
import CoreData

@main
struct FormRecorderApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
