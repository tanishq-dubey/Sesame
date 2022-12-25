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
    
    
    static func load(completion: @escaping (Result<[OTPItem], Error>)->Void) {
        let kChain = Keychain(service: "com.dws.tanishqdubey.Sesame.default")
        let KEYCHAIN_APP_DATA_KEY: String = "otpstoredata"
        DispatchQueue.global(qos: .background).async {
            do {
                guard let data = try kChain.getData(KEYCHAIN_APP_DATA_KEY) else {
                    DispatchQueue.main.async {
                        completion(.success([]))
                    }
                    return
                }
                let lOTPs = try JSONDecoder().decode([OTPItem].self, from: data)
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
        let kChain = Keychain(service: "com.dws.tanishqdubey.Sesame.default")
        let KEYCHAIN_APP_DATA_KEY: String = "otpstoredata"
        
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try JSONEncoder().encode(otps)
                try kChain.set(data, key: KEYCHAIN_APP_DATA_KEY)
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
