//
//  ContentView.swift
//  Sesame
//
//  Created by Tanishq Dubey on 12/18/22.
//

import SwiftUI
import CoreData

struct Person: Identifiable {
     let id = UUID()
     var name: String
     var phoneNumber: String
 }

var staff = [
    Person(name: "Juan Chavez", phoneNumber: "(408) 555-4301"),
    Person(name: "Mei Chen", phoneNumber: "(919) 555-2481")
]

struct ContentView: View {
    var body: some View {
        TOTPList()
    }
}

struct TOTPRowView: View {
    var TOTPItem: Person
    var body: some View {
        Text(TOTPItem.name)
    }
}

struct TOTPList: View {
    var body: some View {
        List(staff) { person in
            TOTPRowView(TOTPItem: person)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
