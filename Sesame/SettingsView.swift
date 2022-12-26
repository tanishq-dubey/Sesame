//
//  SettingsView.swift
//  Sesame
//
//  Created by Tanishq Dubey on 12/23/22.
//

import SwiftUI
import UniformTypeIdentifiers

extension Bundle {
    public var appName: String { getInfo("CFBundleName")  }
    public var displayName: String {getInfo("CFBundleDisplayName")}
    public var language: String {getInfo("CFBundleDevelopmentRegion")}
    public var identifier: String {getInfo("CFBundleIdentifier")}
    public var copyright: String {getInfo("NSHumanReadableCopyright").replacingOccurrences(of: "\\\\n", with: "\n") }
    
    public var appBuild: String { getInfo("CFBundleVersion") }
    public var appVersionLong: String { getInfo("CFBundleShortVersionString") }
    //public var appVersionShort: String { getInfo("CFBundleShortVersion") }
    
    fileprivate func getInfo(_ str: String) -> String { infoDictionary?[str] as? String ?? "⚠️" }
}

struct OTPListFile: FileDocument {
    static var readableContentTypes = [UTType.json]
    
    var text = ""
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        }
    }
    
    init(_ fromList: [OTPItem]) {
        let data = try! JSONEncoder().encode(fromList)
        text = String(decoding: data, as: UTF8.self)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
    
}

struct ExportError: Identifiable {
    var id: String
    var error: Error?
}

struct SettingsView: View {
    @State private var showingExporter = false
    @State private var showingHelp = false
    @State private var exportError: ExportError?
    @Binding var otpList: [OTPItem]
    
    var body: some View {
        List {
            Section("Vault") {
                Button("Export Vault") {
                    showingExporter.toggle()
                }
            }
            Section("About") {
                Button("Help") {
                    showingHelp.toggle()
                }
                HStack {
                    Text("Version")
                    Spacer()
                    Text("\(Bundle.main.appVersionLong) (Build: \(Bundle.main.appBuild))")
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .navigationTitle("Settings")
        .fileExporter(isPresented: $showingExporter, document: OTPListFile(otpList), contentType: .json) { result in
            switch result {
            case .success(_):
                break
            case .failure(let error):
                exportError = ExportError(id: "exportError", error: error)
            }
        }.alert(item: $exportError) { err in
            Alert(title: Text("Could not export key vault"),
                  message: Text("Error: \(err.error!.localizedDescription)"),
                  dismissButton: .default(Text("OK")))
        }.alert(isPresented: $showingHelp) {
            Alert(
                title: Text("Using Sesame"),
                message: Text("Tap on a OTP code to copy it to the clipboard.\n\nLong tap on a HOTP code to increment the counter and copy it to the clipboard.\n\nTapping on the countdown will show you details about the OTP Key. You can also edit key details from here.")
            )
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(otpList: .constant([
            try! OTPItem("otpauth://totp/admin@dws.rip?secret=JBSWY3DPEHPK3PXP&issuer=AWS&algorithm=SHA1&digits=6&period=30"),
            try! OTPItem("otpauth://totp/admin@dws.rip?secret=JBSWY3DPEHPK3PXQ&issuer=AWS256&algorithm=SHA256&digits=6&period=30"),
            try! OTPItem("otpauth://totp/admin@dws.rip?secret=JBSWY3DPEHPK3PXR&issuer=AWS512&algorithm=SHA512&digits=6&period=30"),
            try! OTPItem("otpauth://totp/admin@dws.rip?secret=JBSWY3DPEHPK3PXS&issuer=AWS512&algorithm=SHA512&digits=6&period=45"),
            try! OTPItem("otpauth://hotp/admin@dws.rip?secret=JBSWY3DPEHPK3PXS&issuer=AWS512&algorithm=SHA512&digits=6&period=45&counter=1"),
            try! OTPItem("otpauth://hotp/admin@dws.rip?secret=JBSWY3DPEHPK3PXS&issuer=AWS512&algorithm=SHA512&digits=6&period=45&counter=10"),
        ]))
    }
}
