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
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView(otpList: $store.OTPs) {
                    OTPStore.save(otps: store.OTPs) { result in
                        if case .failure(let failure) = result {
                            fatalError(failure.localizedDescription)
                        }
                    }
                }
            }.onAppear {
                OTPStore.load { result in
                    switch result {
                    case .success(let otps):
                        store.OTPs = otps
                    case .failure(let error):
                        fatalError(error.localizedDescription)
                    }
                }
            }
        }
    }
}
