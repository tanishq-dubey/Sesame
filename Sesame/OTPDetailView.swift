//
//  OTPDetailView.swift
//  Sesame
//
//  Created by Tanishq Dubey on 12/23/22.
//

import SwiftUI
import Combine

struct SecureInputView: View {
    
    @Binding private var text: String
    @State private var isSecured: Bool = true
    private var title: String
    
    init(_ title: String, text: Binding<String>) {
        self.title = title
        self._text = text
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            Group {
                if isSecured {
                    SecureField(title, text: $text).disabled(true)
                } else {
                    TextField(title, text: $text).disabled(true).textSelection(.enabled)
                }
            }.padding(.trailing, 32)

            Button(action: {
                isSecured.toggle()
            }) {
                Image(systemName: self.isSecured ? "eye" : "eye.slash")
                    .accentColor(.gray)
            }
        }
    }
}

struct OTPDetailView: View {
    @Binding var otpItem: OTPItem
    @Binding var otpColor: Color
    @Binding var otpLabel: String
    @Binding var otpCounter: Int
    
    var body: some View {
        List {
            Section(header: Text("Details")) {
                
                HStack {
                    Text("Algorithm")
                    Spacer()
                    Text("\(otpItem.algorithm.description)")
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Type")
                    Spacer()
                    Text("\(otpItem.type.description)")
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Digits")
                    Spacer()
                    Text("\(otpItem.digits)")
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Interval")
                    Spacer()
                    Text("\(otpItem.period) Seconds")
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Secret")
                    Spacer()
                    SecureInputView("OTP Secret", text: .constant("\(otpItem.secret)"))
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.trailing)
                    
                }
            }
            Section(header: Text("Customization")) {
                HStack {
                    Text("Issuer")
                    Spacer()
                    TextField("Issuer", text: $otpLabel)
                        .multilineTextAlignment(.trailing)
                }
                if otpItem.type == OTPType.HOTP {
                    HStack {
                        Text("Counter Value")
                        TextField("Counter", value: $otpCounter, formatter: NumberFormatter())
                            .keyboardType(.numberPad).onChange(of: otpCounter) { _ in
                                otpItem.setCode()
                            }
                        Stepper("Counter", value: $otpCounter, in: 0...Int.max, step: 1).onChange(of: otpCounter) { _ in
                            otpItem.setCode()
                        }
                        .labelsHidden()
                        
                        
                        
                            
                    }
                }
                ColorPicker("Color", selection: $otpColor, supportsOpacity: false)
            }
        }
        .navigationTitle("Key Details")
    }
}

struct OTPDetailView_Previews: PreviewProvider {
    static var previews: some View {
        OTPDetailView(otpItem: .constant(try! OTPItem("otpauth://hotp/DWS%20LLC.:admin@dws.rip?secret=JBSWY3DPEHPK3PXP&issuer=DWS%20LLC.&algorithm=SHA1&digits=6&period=30")), otpColor: .constant(Color.random), otpLabel: .constant("TestLabel"), otpCounter: .constant(1))
    }
}
