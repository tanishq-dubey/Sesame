//
//  OTPModel.swift
//  Sesame
//
//  Created by Tanishq Dubey on 12/19/22.
//

import Foundation

enum OTPAlgorithm {
    case SHA1
    case SHA256
    case SHA512
}

enum OTPType {
    case HOTP
    case TOTP
}

struct OTPItem: Identifiable {
    // A OTPItem represents a single OTP (TOTP or HOTP) key.
    // This item is generated via QR code or URL in the following format:
    //
    // otpauth://totp/ACME%20Co:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME%20Co&algorithm=SHA1&digits=6&period=30
    //
    // Here we have the otpauth URL scheme indicating it is for OTP:
    //  - The totp portion differentiates HOTP or TOTP (HMAC or Time)
    //  - The ACME%20Co:john@example.com is the label. The issuer can be inferred from this
    //  - The secret is the secret key (required)
    //  - The issuer is the issuer (optional)
    //  - The algorithm is the hashing to use in HMAC (SHA1*, SHA256, SHA512) (optional)
    //  - The digits is how big of a code to generate (6*, 8) (optional)
    //  - The period (only valid on TOTP) is the time interval (30*) (optional)
    //  - The counter (only valid on HOTP) is the initial sync counter (required)

    // Generic UUID for unique identification in CoreData
    let id = UUID()
    
    // The type is either HOTP or TOTP. We default to TOTP since it is the most common
    var type: OTPType = OTPType.TOTP
    
    // The secret is a Base32 encoded string of the secret key shared between
    // client and user.
    var secret: String
    
    // The issuer is a string indicating the provider or service the key is associated with. It is URL-encoded.
    // If this parameter is not available, the issuer can be taken from the prefix on the label.
    var issuer: String
    
    // The algorithm to use when hashing in HMAC. SHA1 is the most common.
    var algorithm: OTPAlgorithm = OTPAlgorithm.SHA1
    
    // The number of digits to present to the user for OTP, defaults to 6.
    var digits: Int = 6
    
    // The TOTP sync period in seconds. This is the amount of time the code is valid for. Only valid when type is TOTP
    var period: Int = 30
    
    // Only if using HOTP, the user has to enter an initial counter number to sync with the server.
    var counter: Int = 0
}
