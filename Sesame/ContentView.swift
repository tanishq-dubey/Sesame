//
//  ContentView.swift
//  Sesame
//
//  Created by Tanishq Dubey on 12/18/22.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @State var otpList = [
        try! OTPItem("otpauth://totp/DWS%20LLC.:admin@dws.rip?secret=SESAMETEST&issuer=DWS%20LLC.&algorithm=SHA1&digits=6&period=30"),
        try! OTPItem("otpauth://hotp/DWS%20LLC.:admin@dws.rip?secret=SESAMETEST&algorithm=SHA1&digits=6&period=30")
    ]
    
    var body: some View {
        NavigationStack{
            TOTPList(otpList: $otpList)
                .navigationTitle("Sesame")
                .toolbar{
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Edit") {
                            print("hello")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Add New") {
                            print("hello")
                        }
                    }
                }
        }
    }
    
    func addOTP() {
        
    }
}

struct TOTPRowView: View {
    var TOTPItem: OTPItem
    var body: some View {
        VStack{
            Text(TOTPItem.secret)
            HStack{
                Text(TOTPItem.issuer)
                    .font(.subheadline)
                Spacer()
                Text(TOTPItem.type.description)
            }
            
        }
        
    }
}

struct TOTPList: View {
    @Binding var otpList: [OTPItem]
    var body: some View {
        List(otpList) { otp in
            TOTPRowView(TOTPItem: otp)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
