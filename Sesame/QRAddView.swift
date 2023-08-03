//
//  QRAddView.swift
//  Sesame
//
//  Created by Tanishq Dubey on 1/8/23.
//

import SwiftUI
import GAuthSwiftParser

struct QRAddView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State private var showingAdd = false
    @State private var addError: String = ""
    
    @Binding var otpItems: [OTPItem]
    
    
    var body: some View {
        CodeScannerView(codeTypes: [.qr], simulatedData: "otpauth://hotp/DWS%20LLC.:admin@dws.rip?secret=SESAMETEST&algorithm=SHA1&digits=6&period=30", completion: handleScan)
            .alert(isPresented: $showingAdd) {
            Alert(
                title: Text("Could not add OTP"),
                message: Text(addError),
                dismissButton: .default(Text("OK"), action: {
                    self.presentationMode.wrappedValue.dismiss()
                })
            )
        }
        .navigationBarTitle("Scan A QR Code")
    }
    
    func handleScan(result: Result<ScanResult, ScanError>) {
        switch result {
        case .success(let result):
            let details = result.string
            do {
                if details.starts(with: "otpauth-migration") {
                    let data = GAuthSwiftParser.getAccounts(code: details)
                    for otp in data {
                        let item = try OTPItem(otp.getLink())
                        otpItems.append(item)
                    }
                } else {
                    let item = try OTPItem(details)
                    otpItems.append(item)
                }
                self.presentationMode.wrappedValue.dismiss()
            } catch OTPError.malformedInput {
                showingAdd.toggle()
                addError = "The OTP URL is malformed, please double check it: \(details)"
            } catch OTPError.parsingError {
                showingAdd.toggle()
                addError = "There was an error parsing the OTP details: \(details)"
            } catch {
                showingAdd.toggle()
                addError = "An unknown error has happened while adding the OTP code: \(details)"
            }
        case .failure(let error):
            addError = "Could not successfully scan the OTP QR code: \(error.localizedDescription)"
        }
    }
}

struct QRAddView_Previews: PreviewProvider {
    static var previews: some View {
        QRAddView(otpItems: .constant([
            try! OTPItem("otpauth://totp/admin@dws.rip?secret=JBSWY3DPEHPK3PXP&issuer=AWS&algorithm=SHA1&period=30"),
            try! OTPItem("otpauth://totp/admin@dws.rip?secret=JBSWY3DPEHPK3PXQ&issuer=AWS256&algorithm=SHA256&digits=8&period=30"),
            try! OTPItem("otpauth://totp/admin@dws.rip?secret=JBSWY3DPEHPK3PXR&issuer=AWS512&algorithm=SHA512&digits=6&period=30"),
            try! OTPItem("otpauth://totp/admin@dws.rip?secret=JBSWY3DPEHPK3PXS&issuer=AWS512&algorithm=SHA512&digits=6&period=45"),
            try! OTPItem("otpauth://hotp/admin@dws.rip?secret=JBSWY3DPEHPK3PXT&issuer=AWS512&digits=6&period=45"),
            try! OTPItem("otpauth://hotp/admin@dws.rip?secret=JBSWY3DPEHPK3PXU&issuer=AWS256&algorithm=SHA256&digits=6&period=45&counter=1"),
            try! OTPItem("otpauth://hotp/admin@dws.rip?secret=JBSWY3DPEHPK3PXV&issuer=AWS512&algorithm=SHA512&digits=8&period=45&counter=10"),
        ]))
    }
}
