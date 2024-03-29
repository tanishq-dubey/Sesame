//
//  OTPStore.swift
//  Sesame
//
//  Created by Tanishq Dubey on 12/22/22.
//

import Foundation
import SwiftUI
import KeychainAccess

class OTPStore: ObservableObject {
    @Published var OTPs: [OTPItem] = []
    @Published var lastTime: Int = 0
    
    
    static func load(completion: @escaping (Result<[OTPItem], Error>)->Void) {
#if DEBUG
    let kChain = Keychain(service: "com.dws.tanishqdubey.Sesame.default").synchronizable(true)
#else
    let kChain = Keychain(service: "com.dws.Sesame.default").synchronizable(true)
#endif
        let KEYCHAIN_APP_DATA_KEY: String = "otpstoredata"
        let KEYCHAIN_APP_TIME_KEY: String = "otpstoremodtime"
        
        DispatchQueue.global(qos: .background).async {
            do {
                guard let data = try kChain.getData(KEYCHAIN_APP_DATA_KEY) else {
                    DispatchQueue.main.async {
                        completion(.success([]))
                    }
                    return
                }
                var tString = "0"
                if let tmod = try kChain.getData(KEYCHAIN_APP_TIME_KEY) {
                    if let dataString = String(data: tmod, encoding: .utf8) {
                        tString = dataString
                    }
                }
                
                if let tnumber = Int(tString) {
                    let timeInterval = NSDate().timeIntervalSince1970
                    let tData = Int(timeInterval)
                }
                
                let lOTPs = try JSONDecoder().decode([OTPItem].self, from: data)
                if (lOTPs.isEmpty) {
                    // Should only need for one build, but will keep this here.
                    // This will migrate users from the old key to the release iCloud synced key
                    let kChainLegacy = Keychain(service: "com.dws.tanishqdubey.Sesame.default")
                    guard let d = try kChainLegacy.getData(KEYCHAIN_APP_DATA_KEY) else {
                        DispatchQueue.main.async {
                            completion(.success([]))
                        }
                        return
                    }
                    let lOTPslegacy = try JSONDecoder().decode([OTPItem].self, from: d)
                    DispatchQueue.main.async {
                        completion(.success(lOTPslegacy))
                    }
                    return
                }
                DispatchQueue.main.async {
                    completion(.success(lOTPs))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    static func save(otps: [OTPItem], completion: @escaping (Result<Int, Error>)->Void) {
#if DEBUG
    let kChain = Keychain(service: "com.dws.tanishqdubey.Sesame.default").synchronizable(true)
#else
    let kChain = Keychain(service: "com.dws.Sesame.default").synchronizable(true)
#endif
        let KEYCHAIN_APP_DATA_KEY: String = "otpstoredata"
        let KEYCHAIN_APP_TIME_KEY: String = "otpstoremodtime"
        
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try JSONEncoder().encode(otps)
                let timeInterval = NSDate().timeIntervalSince1970
                let tData = String(Int(timeInterval))
                
                try kChain.synchronizable(true).set(data, key: KEYCHAIN_APP_DATA_KEY)
                try kChain.synchronizable(true).set(tData, key: KEYCHAIN_APP_TIME_KEY)
                
                
                DispatchQueue.main.async {
                    completion(.success(otps.count))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}
