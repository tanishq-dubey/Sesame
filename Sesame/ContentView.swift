//
//  ContentView.swift
//  Sesame
//
//  Created by Tanishq Dubey on 12/18/22.
//

import SwiftUI
import CoreData
import CodeScanner

struct AddSheetView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Button("dismiss") {
            dismiss()
        }
    }
}

struct ContentView: View {
    @State private var showingAdd = false
    
    @State var otpList: [OTPItem] = [
        try! OTPItem("otpauth://totp/ACME%20Co:john@example.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME%20Co&algorithm=SHA1&digits=6&period=30")
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
                            showingAdd = true
                        }
                    }
                }
                .sheet(isPresented: $showingAdd) {
                    VStack{
                        CodeScannerView(codeTypes: [.qr], simulatedData: "otpauth://hotp/DWS%20LLC.:admin@dws.rip?secret=SESAMETEST&algorithm=SHA1&digits=6&period=30", completion: handleScan)
                        Text("testing")
                    }
                    
                }
        }
    }
    
    func handleScan(result: Result<ScanResult, ScanError>) {
        showingAdd = false
        switch result {
        case .success(let result):
            let details = result.string
            print(details)
            do {
                let item = try OTPItem(details)
                print(item.generateCode())
                otpList.append(item)
            } catch OTPError.malformedInput {
                print("malformed input: \(details)")
            } catch OTPError.parsingError {
                print("parsing error: \(details)")
            } catch {
                print("who knows what")
            }
            
        case .failure(let error):
            print(error.localizedDescription)
        }
    }
    
}

struct TOTPRowView: View {
    var TOTPItem: OTPItem
    var body: some View {
        VStack{
            Text(TOTPItem.currentValue)
                .font(.title)
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
