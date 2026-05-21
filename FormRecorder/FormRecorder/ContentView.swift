//
//  ContentView.swift
//  FormRecorder
//
//  Created by Param Grewal on 2026-02-24.
//

import CoreData
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            NavigationStack {
                RecordView()
            }
            .tabItem {
                Label("Record", systemImage: "camera.fill")
            }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
