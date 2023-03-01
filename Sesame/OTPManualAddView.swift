//
//  OTPManualAddView.swift
//  Sesame
//
//  Created by Tanishq Dubey on 1/8/23.
//

import SwiftUI

struct OTPManualAddView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @Binding var otpList: [OTPItem]
    
    @State var issuer: String = ""
    @State var color: Color = Color.random
    @State var type: OTPType = OTPType.TOTP
    @State var algorithm: OTPAlgorithm = OTPAlgorithm.SHA1
    @State var digits: Int = 6
    @State var counter: Int = 0
    @State var interval: Int = 30
    @State var secret: String = ""
    
    @State var nameInvalid: Bool = true
    @State var secretInvalid: Bool = true
    
    @State private var showingAdd = false
    @State private var addError: String = ""
    
    var body: some View {
        HStack{
            Spacer()
            Form {
                Section(header: Text("Basic Information")) {
                    HStack {
                        Text("Key Name")
                        Spacer()
                        TextField("Name", text: $issuer)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: issuer, perform: {newVal in
                                if newVal.count <= 0 {
                                    nameInvalid = true
                                } else {
                                    nameInvalid = false
                                }
                            })
                    }
                    ColorPicker("Color", selection: $color, supportsOpacity: false)
                }
                Section(header: Text("Key Details")) {
                    Picker("OTP Type", selection: $type) {
                        Text("TOTP").tag(OTPType.TOTP)
                        Text("HOTP").tag(OTPType.HOTP)
                    }
                    Picker("OTP Algorithm", selection: $algorithm) {
                        Text("SHA1").tag(OTPAlgorithm.SHA1)
                        Text("SHA256").tag(OTPAlgorithm.SHA256)
                        Text("SHA512").tag(OTPAlgorithm.SHA512)
                    }
                    HStack {
                        Text("Key Length")
                        Spacer()
                        TextField("Length", value: $digits, formatter: NumberFormatter())
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Key Internval")
                        Spacer()
                        TextField("Interval", value: $interval, formatter: NumberFormatter()).multilineTextAlignment(.trailing)
                    }
                    if type == OTPType.HOTP {
                        HStack {
                            Text("Counter Value")
                            TextField("Counter", value: $counter, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                            Stepper("Counter", value: $counter, in: 0...Int.max, step: 1)
                            .labelsHidden()
                            .multilineTextAlignment(.trailing)
                        }
                    }
                    HStack {
                        Text("Key Secret")
                        Spacer()
                        SecureField("Key Secret", text: $secret)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: secret, perform: {newVal in
                                if newVal.count <= 0 {
                                    secretInvalid = true
                                } else {
                                    secretInvalid = false
                                }
                            })
                    }
                }
                Section {
                    Button(action: {
                        let item = OTPItem(type: type, secret: secret, issuer: issuer, algorithm: algorithm, digits: digits, period: interval, counter: counter, color: color)
                        otpList.append(item)
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Add Key")
                    }.disabled(secretInvalid || nameInvalid)
                }
            }
            Spacer()
        }
        .navigationBarTitle("Add New OTP")
    }
}

struct OTPManualAddView_Previews: PreviewProvider {
    static var previews: some View {
        OTPManualAddView(otpList: .constant([
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
