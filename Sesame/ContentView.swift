//
//  ContentView.swift
//  Sesame
//
//  Created by Tanishq Dubey on 12/18/22.
//

import SwiftUI
import CoreData
import CodeScanner
import AlertToast

struct ContentView: View {
    @State private var showingAdd = false
    @State private var showingManualAdd = false
    @State private var addError: String = ""
    
    @Binding var otpList: [OTPItem]
    @State var showCopyToast: Bool = false
    
    @Environment(\.scenePhase) private var scenePhase
    
    let saveAction: ()->Void
    
    var body: some View {
        NavigationStack{
            NavigationLink(destination: QRAddView(otpItems: $otpList), isActive: $showingAdd) {}
            List {
                ForEach ($otpList) { o in
                    OTPRowView(otpList: $otpList, otpItem: o, otpcolor: o.otpColor, otpLabel: o.issuer, otpCounter: o.counter, showCopyToast: $showCopyToast)
                }
                
            }
            .toast(isPresenting: $showCopyToast){
                AlertToast(displayMode: .hud, type: .regular, title: "Code copied to clipboard!")
            }
            .navigationTitle("Keys")
            .toolbar{
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: {
                            showingAdd.toggle()
                        }) {
                            Label("Add by QR Code", systemImage: "qrcode.viewfinder")
                        }

                        Button(action: {
                            
                        }) {
                            Label("Add Manually", systemImage: "plus")
                        }
                    }
                    label: {
                        Label("Add", systemImage: "plus")
                    }
                }
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
}

struct OTPRowView: View {
    @Binding var otpList: [OTPItem]
    @Binding var otpItem: OTPItem
    @Binding var otpcolor: Color
    @Binding var otpLabel: String
    @Binding var otpCounter: Int
    @Binding var showCopyToast: Bool
    
    @State private var isDetailActive = false
    
    var body: some View {
        NavigationLink {
            OTPDetailView(otpItem: $otpItem, otpColor: $otpcolor, otpLabel: $otpLabel, otpCounter: $otpCounter)
        } label: {
            TimelineView(.periodic(from: .now, by: 1)) { ctx in
                if otpItem.type == OTPType.TOTP || otpItem.currentValue == "" {
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
                                .lineLimit(1)
                        }
                    }.onTapGesture {
                        let pasteboard = UIPasteboard.general
                        pasteboard.string = otpItem.currentValue.replacingOccurrences(of: " ", with: "")
                        showCopyToast.toggle()
                    }.onLongPressGesture {
                        otpItem.counter += 1
                        otpItem.setCode()
                        let pasteboard = UIPasteboard.general
                        pasteboard.string = otpItem.currentValue.replacingOccurrences(of: " ", with: "")
                        showCopyToast.toggle()
                    }
                    Spacer()
                    if otpItem.type == OTPType.TOTP {
                        let prog = CGFloat(otpItem.counter)/CGFloat(otpItem.period)
                        ZStack{
                            Circle()
                                .trim(from: 0, to: prog)
                                .stroke(otpItem.otpColor, lineWidth: 3)
                                .animation(.spring(), value: prog)
                                .frame(minWidth: 16, maxWidth: 64, minHeight: 16, maxHeight: 64)
                                .overlay(
                                    Text(String(otpItem.counter))
                                        .font(.footnote)
                                        .rotationEffect(.degrees(90))
                                )
                            Spacer()
                        }
                        .rotationEffect(.degrees(-90))
                    } else {
                        ZStack{
                            Circle()
                                .stroke(otpItem.otpColor, lineWidth: 3)
                                .frame(minWidth: 16, maxWidth: 64, minHeight: 16, maxHeight: 64)
                                .overlay(
                                    Text(String(otpItem.counter))
                                        .font(.footnote)
                                        .multilineTextAlignment(.center)
                                        .rotationEffect(.degrees(90))
                                )
                            Spacer()
                        }
                        .rotationEffect(.degrees(-90))
                    }
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
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(otpList: .constant([
            try! OTPItem("otpauth://totp/admin@dws.rip?secret=JBSWY3DPEHPK3PXP&issuer=AWS&algorithm=SHA1&period=30"),
            try! OTPItem("otpauth://totp/admin@dws.rip?secret=JBSWY3DPEHPK3PXQ&issuer=AWS256&algorithm=SHA256&digits=8&period=30"),
            try! OTPItem("otpauth://totp/admin@dws.rip?secret=JBSWY3DPEHPK3PXR&issuer=AWS512&algorithm=SHA512&digits=6&period=30"),
            try! OTPItem("otpauth://totp/admin@dws.rip?secret=JBSWY3DPEHPK3PXS&issuer=AWS512&algorithm=SHA512&digits=6&period=45"),
            try! OTPItem("otpauth://hotp/admin@dws.rip?secret=JBSWY3DPEHPK3PXT&issuer=AWS512&digits=6&period=45"),
            try! OTPItem("otpauth://hotp/admin@dws.rip?secret=JBSWY3DPEHPK3PXU&issuer=AWS256&algorithm=SHA256&digits=6&period=45&counter=1"),
            try! OTPItem("otpauth://hotp/admin@dws.rip?secret=JBSWY3DPEHPK3PXV&issuer=AWS512&algorithm=SHA512&digits=8&period=45&counter=10"),
        ]), saveAction: {})
    }
}
