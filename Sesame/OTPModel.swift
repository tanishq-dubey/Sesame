//
//  OTPModel.swift
//  Sesame
//
//  Created by Tanishq Dubey on 12/19/22.
//

import Foundation
import Base32
import CryptoKit
import SwiftUI

extension String {
    func separated(by separator: String = " ", stride: Int = 4) -> String {
        return enumerated().map { $0.isMultiple(of: stride) && ($0 != 0) ? "\(separator)\($1)" : String($1) }.joined()
    }
}

extension Color {
    static var random: Color {
        return Color(red: .random(in: 0...1),
                     green: .random(in: 0...1),
                     blue: .random(in: 0...1))
    }
}

public extension Data {
    private static let hexAlphabet = Array("0123456789abcdef".unicodeScalars)
    func hexStringEncoded() -> String {
        String(reduce(into: "".unicodeScalars) { result, value in
            result.append(Self.hexAlphabet[Int(value / 0x10)])
            result.append(Self.hexAlphabet[Int(value % 0x10)])
        })
    }
}

#if os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#elseif os(macOS)
import AppKit
#endif

fileprivate extension Color {
    #if os(macOS)
    typealias SystemColor = NSColor
    #else
    typealias SystemColor = UIColor
    #endif
    
    var colorComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        #if os(macOS)
        SystemColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        // Note that non RGB color will raise an exception, that I don't now how to catch because it is an Objc exception.
        #else
        guard SystemColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else {
            // Pay attention that the color should be convertible into RGB format
            // Colors using hue, saturation and brightness won't work
            return nil
        }
        #endif
        
        return (r, g, b, a)
    }
}

extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let r = try container.decode(Double.self, forKey: .red)
        let g = try container.decode(Double.self, forKey: .green)
        let b = try container.decode(Double.self, forKey: .blue)
        
        self.init(red: r, green: g, blue: b)
    }

    public func encode(to encoder: Encoder) throws {
        guard let colorComponents = self.colorComponents else {
            return
        }
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(colorComponents.red, forKey: .red)
        try container.encode(colorComponents.green, forKey: .green)
        try container.encode(colorComponents.blue, forKey: .blue)
    }
}

enum OTPAlgorithm: Codable {
    case SHA1
    case SHA256
    case SHA512
    
    var description : String {
        switch self {
            
        case .SHA1:
            return "SHA1"
        case .SHA256:
            return "SHA256"
        case .SHA512:
            return "SHA512"
        }
    }
}

enum OTPType: Codable, CustomStringConvertible {
    case HOTP
    case TOTP
    
    var description: String {
        switch self {
        case .HOTP: return "HOTP"
        case .TOTP: return "TOTP"
        }
    }
}

enum OTPError: Codable, Error {
    case parsingError(reason: String)
    case malformedInput
}

class OTPItem: Identifiable, Codable, Equatable {
    static func == (lhs: OTPItem, rhs: OTPItem) -> Bool {
        return (lhs.secret == rhs.secret) &&
        (lhs.issuer == rhs.issuer) &&
        (lhs.algorithm == rhs.algorithm) &&
        (lhs.type == rhs.type) &&
        (lhs.digits == rhs.digits) &&
        (lhs.period == rhs.period) &&
        (lhs.counter == rhs.counter) &&
        (lhs.otpColor == rhs.otpColor)
    }
    
    /// A OTPItem represents a single OTP (TOTP or HOTP) key.
    /// This item is generated via QR code or URL in the following format:
    
    // otpauth://totp/DWS%20LLC.:admin@dws.rip?secret=SESAMETEST&issuer=DWS%20LLC.&algorithm=SHA1&digits=6&period=30
    //
    /// Here we have the otpauth URL scheme indicating it is for OTP:
    ///  - The totp portion differentiates HOTP or TOTP (HMAC or Time)
    ///  - The DWS%20LLC.:admin@dws.rip is the label. The issuer can be inferred from this
    ///  - The secret is the secret key (required)
    ///  - The issuer is the issuer (optional)
    ///  - The algorithm is the hashing to use in HMAC (SHA1*, SHA256, SHA512) (optional)
    ///  - The digits is how big of a code to generate (6*, 8) (optional)
    ///  - The period (only valid on TOTP) is the time interval (30*) (optional)
    ///  - The counter (only valid on HOTP) is the initial sync counter (required)

    /// Generic UUID for unique identification in CoreData
    var id = UUID()
    
    /// The type is either HOTP or TOTP. We default to TOTP since it is the most common
    var type: OTPType = OTPType.TOTP
    
    /// The secret is a Base32 encoded string of the secret key shared between client and user.
    var secret: String
    
    /// The issuer is a string indicating the provider or service the key is associated with. It is URL-encoded.
    /// If this parameter is not available, the issuer can be taken from the prefix on the label.
    var issuer: String
    
    /// The algorithm to use when hashing in HMAC. SHA1 is the most common.
    var algorithm: OTPAlgorithm = OTPAlgorithm.SHA1
    
    /// The number of digits to present to the user for OTP, defaults to 6.
    var digits: Int = 6
    
    /// The TOTP sync period in seconds. This is the amount of time the code is valid for. Only valid when type is TOTP
    var period: Int = 30
    
    /// Only if using HOTP, the user has to enter an initial counter number to sync with the server.
    /// We can also overload this value for TOTP, using it to indicate when the next value will appear
    var counter: Int = 0
    
    /// We can use this variable as an easy way to keep the current OTP, just cycle through the list and update this
    var currentValue: String = ""
    
    /// Color of the countdown
    var otpColor: Color = Color(red: Double.random(in: 0.0 ..< 1.0), green: Double.random(in: 0.0 ..< 1.0), blue: Double.random(in: 0.0 ..< 1.0))

    private func generateHOTP(intervalCounter: Int) -> String {
        var padding: String = ""
        switch self.secret.count {
        case 2:
            padding = "======"
        case 4:
            padding = "===="
        case 5:
            padding = "==="
        case 7:
            padding = "=="
        default:
            padding = ""
        }
//        print("Key: \(self.secret)")
//        print("Counter: \(intervalCounter)")
        let key = Base32.base32Decode(self.secret.uppercased() + padding)
        let counter = UInt64(intervalCounter)
        var packedCounter = Data(count: MemoryLayout<UInt64>.size)
//        print("Key: \(String(describing: key))")

        packedCounter.withUnsafeMutableBytes { bytes in
            bytes.storeBytes(of: counter.bigEndian, as: UInt64.self)
        }
//        print("Counter: \(packedCounter.hexStringEncoded())")
        
        if key == nil {
            return "XXX XXX"
        }
        var mac = Data(HMAC<Insecure.SHA1>.authenticationCode(for: packedCounter, using: SymmetricKey(data: key!)))
        switch self.algorithm {
        case .SHA1:
            mac = Data(HMAC<Insecure.SHA1>.authenticationCode(for: packedCounter, using: SymmetricKey(data: key!)))
        case .SHA256:
            mac = Data(HMAC<SHA256>.authenticationCode(for: packedCounter, using: SymmetricKey(data: key!)))
        case .SHA512:
            mac = Data(HMAC<SHA512>.authenticationCode(for: packedCounter, using: SymmetricKey(data: key!)))
        }
//        print("Mac: \(mac.hexStringEncoded())")
        
        
        let offset = Int(mac[mac.count - 1]) & 0x0f
//        print("Offset: \(offset)")

        let binary = UInt32(bigEndian: Data(mac[offset..<offset+4]).withUnsafeBytes { $0.load(as: UInt32.self) }) & 0x7fffffff

        var bString = String(binary)
//        print("Binary: \(bString), \(binary)")
        if bString.count < self.digits {
            bString = bString.padding(toLength: self.digits, withPad: "0", startingAt: 0)
        }
//        print()
        return String(bString.suffix(self.digits))
    }
    
    func generateCode() -> String {
        if self.type == OTPType.TOTP {
            self.counter = self.period - Int(Int(NSDate().timeIntervalSince1970) % self.period)
            return generateHOTP(intervalCounter: Int(Int(NSDate().timeIntervalSince1970) / self.period))
        }
        return generateHOTP(intervalCounter: self.counter)
    }
    
    func setCode() {
        self.currentValue = generateCode().separated(by: " ", stride: 3)
    }
    
    func createURL() -> String {
        if self.type == OTPType.HOTP {
            return "otpauth://\(self.type.description.lowercased())/\(self.issuer.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)?secret=\(self.secret)&issuer=\(self.issuer.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)&algorithm=\(self.algorithm.description)&digits=\(self.digits)&period=\(self.period)&counter=\(self.counter)"
        }
        return "otpauth://\(self.type.description.lowercased())/\(self.issuer.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)?secret=\(self.secret)&issuer=\(self.issuer.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)&algorithm=\(self.algorithm.description)&digits=\(self.digits)&period=\(self.period)"
    }
    
    init(type: OTPType, secret: String, issuer: String, algorithm: OTPAlgorithm, digits: Int, period: Int, counter: Int, color: Color) {
        self.type = type
        self.secret = secret
        self.issuer = issuer
        self.algorithm = algorithm
        self.digits = digits
        self.period = period
        self.counter = counter
        self.otpColor = color
    }
    
    /// Initialize a OTP object from a OTP URL. This intitalizer can throw exceptions if the URL is malformed
    init(_ fromURL: String) throws {
        let url = URL(string: fromURL)
        if url == nil {
            throw OTPError.parsingError(reason: "Could not parse OTP URL")
        }
        
        let rawType = url?.host
        if rawType == nil {
            throw OTPError.parsingError(reason: "Could not parse OTP type")
        }
        switch rawType?.lowercased() {
        case "totp":
            self.type = OTPType.TOTP
        case "hotp":
            self.type = OTPType.HOTP
        default:
            throw OTPError.parsingError(reason: "Could not parse OTP type")
        }
        
        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        if components == nil {
            throw OTPError.parsingError(reason: "Could not parse OTP URL components")
        }
        if components?.queryItems == nil || components?.queryItems?.count ?? 0 < 1 {
            throw OTPError.parsingError(reason: "Could not parse OTP URL components")
        }
        
        let rawSecret = components?.queryItems?.filter({
            $0.name == "secret"
        }).first
        if rawSecret == nil {
            throw OTPError.malformedInput
        }
        if rawSecret?.value == nil {
            throw OTPError.parsingError(reason: "Could not parse OTP secret")
        }
        self.secret = rawSecret!.value!
        
        // If the components has a issuer string, we can use that, otherwise, we should attempt to parse out the raw label
        let rawLabel = url?.path(percentEncoded: false)
        let rawIssuer = components?.queryItems?.filter({
            $0.name == "issuer"
        }).first
        if rawIssuer == nil {
            // No issuer has be found in the URL, we should use the label
            // TODO: Add proper parsing here, for testing, we are going to leave it as is
            if rawLabel == nil {
                throw OTPError.parsingError(reason: "Could not parse a issuer or a label for the OTP")
            }
            self.issuer = rawLabel!.replacingOccurrences(of: "/", with: "")
        } else {
            // Issuer does exist, we can use it as is
            if rawLabel == nil {
                self.issuer = (rawIssuer!.value ?? "Label Not found")
            } else {
                let label = rawLabel!.replacingOccurrences(of: "/", with: "")
                self.issuer = (rawIssuer!.value ?? "Label Not found") + " (\(label))"
            }
        }
        
        let rawAlgorithm = components?.queryItems?.filter({
            $0.name == "algorithm"
        }).first
        if rawAlgorithm == nil {
            self.algorithm = OTPAlgorithm.SHA1
        } else {
            if rawAlgorithm?.value != nil {
                switch rawAlgorithm!.value!.lowercased() {
                case "sha1":
                    self.algorithm = OTPAlgorithm.SHA1
                case "sha256":
                    self.algorithm = OTPAlgorithm.SHA256
                case "sha512":
                    self.algorithm = OTPAlgorithm.SHA512
                default:
                    throw OTPError.parsingError(reason: "Could not parse algorithm")
                }
            }
        }
        
        if let rawDigits = components?.queryItems?.filter({
            $0.name == "digits"
        }).first {
            self.digits = Int(rawDigits.value ?? "6") ?? 6
        }
        
        if let rawPeriod = components?.queryItems?.filter({
            $0.name == "period"
        }).first {
            self.period = Int(rawPeriod.value ?? "30") ?? 30
        }
        
        if let rawCounter = components?.queryItems?.filter({
            $0.name == "counter"
        }).first {
            self.counter = Int(rawCounter.value ?? "0") ?? 0
        }
        
    }
}
