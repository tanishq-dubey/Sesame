//
//  SesameApp.swift
//  Sesame
//
//  Created by Tanishq Dubey on 12/18/22.
//

import SwiftUI

@main
struct SesameApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
