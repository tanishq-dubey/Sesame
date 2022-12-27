//
//  SesameApp.swift
//  Sesame
//
//  Created by Tanishq Dubey on 12/18/22.
//

import SwiftUI

@main
struct SesameApp: App {
    @StateObject private var store = OTPStore()
    
    @State private var showingRootAlert: Bool = false
    @State private var rootAlertMessage: String = ""
    
    var body: some Scene {
        WindowGroup {
            TabView{
                NavigationView {
                    ContentView(otpList: $store.OTPs) {
                        OTPStore.save(otps: store.OTPs) { result in
                            if case .failure(let failure) = result {
                                rootAlertMessage = "There was an error saving the keys to the keychain: \(failure.localizedDescription)"
                                showingRootAlert.toggle()
                            }
                        }
                    }
                }.onAppear {
                    OTPStore.load { result in
                        switch result {
                        case .success(let otps):
                            store.OTPs = otps
                        case .failure(let error):
                            rootAlertMessage = "There was an error loading the keys from the keychain: \(error.localizedDescription)"
                            showingRootAlert.toggle()
                        }
                    }
                }.tabItem{
                    Label("Keys", systemImage: "key")
                }
                
                NavigationView {
                    SettingsView(otpList: $store.OTPs)
                }
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
    }
}
