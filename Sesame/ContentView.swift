//
//  ContentView.swift
//  Sesame
//
//  Created by Tanishq Dubey on 12/18/22.
//

import SwiftUI
import CoreData
import CodeScanner

//struct AddSheetView: View {
//    @Environment(\.dismiss) var dismiss
//
//    var body: some View {
//        Button("dismiss") {
//            dismiss()
//        }
//    }
//}

struct ContentView: View {
    @State private var showingAdd = false
    @Binding var otpList: [OTPItem]
    @Environment(\.scenePhase) private var scenePhase
    let saveAction: ()->Void
    
    var body: some View {
        NavigationStack{
            OTPListView(otpList: $otpList)
                .navigationTitle("Sesame")
                .toolbar{
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingAdd = true
                        }){
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingAdd) {
                    VStack{
                        CodeScannerView(codeTypes: [.qr], simulatedData: "otpauth://hotp/DWS%20LLC.:admin@dws.rip?secret=SESAMETEST&algorithm=SHA1&digits=6&period=30", completion: handleScan)
                        Button("Cancel") {
                            showingAdd = false
                        }.padding(.vertical)
                    }
                    .padding(.bottom)
                    
                }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .inactive {
                saveAction()
            }
        }.onChange(of: otpList) { _ in
            saveAction()
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

struct OTPRowView: View {
    @Binding var otpList: [OTPItem]
    @State private var showCopyToast = false
    
    var otpItem: OTPItem
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            if otpItem.type == OTPType.TOTP || otpItem.counter == 0 {
                let _ = otpItem.setCode()
            }
            HStack {
                VStack(alignment: .leading){
                    HStack{
                        Text(otpItem.currentValue)
                            .font(.title)
                        Spacer()
                    }
                    HStack(){
                        Text(otpItem.issuer)
                            .font(.subheadline)
                    }
                }
                Spacer()
                if otpItem.type == OTPType.TOTP {
                    let prog = CGFloat(otpItem.counter)/CGFloat(otpItem.period)
                    ZStack{
                        Circle()
                            .trim(from: 0, to: prog)
                            .stroke(Color.orange, lineWidth: 3)
                            .animation(.spring(), value: prog)
                            .frame(minWidth: 16, maxWidth: 64, minHeight: 16, maxHeight: 64)
                            .overlay(
                                Text(String(otpItem.counter))
                                    .font(.subheadline)
                                    .rotationEffect(.degrees(90))
                            )
                        Spacer()
                    }
                    .rotationEffect(.degrees(-90))
                } else {
                    Text("Current Counter: \(otpItem.counter)")
                }
            }
        }.swipeActions(allowsFullSwipe: false) {
            Button(role: .destructive) {
                otpList.removeAll(where: {
                    $0.id == otpItem.id
                })
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
            Button(role: .none) {
                
            } label: {
                Label("Edit", systemImage: "pencil.circle.fill")
            }
        }.onTapGesture {
            let pasteboard = UIPasteboard.general
            pasteboard.string = otpItem.currentValue.replacingOccurrences(of: " ", with: "")
            showCopyToast.toggle()
        }
    }
}

struct OTPListView: View {
    @Binding var otpList: [OTPItem]
    
    var body: some View {
        List(otpList) { otp in
            OTPRowView(otpList: $otpList, otpItem: otp)
        }
    }
}
