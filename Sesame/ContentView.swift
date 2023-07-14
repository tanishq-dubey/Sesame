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

struct CustomEditButton: View {
    @Binding var editMode: EditMode
    
    var body: some View {
      Button {
        switch editMode {
        case .active: editMode = .inactive
        case .inactive: editMode = .active
        default: break
        }
      } label: {
        if editMode.isEditing {
          Text("Done")
        } else {
          Text("Edit")
        }
      }
    }
}

struct ContentView: View {
    @State private var showingAdd = false
    @State private var showingManualAdd = false
    @State private var addError: String = ""
    @State private var confirmationShown = false
    @State private var itemToDelete: OTPItem? = nil
    @State var showCopyToast: Bool = false
    @State private var editMode = EditMode.inactive
    
    @Binding var otpList: [OTPItem]
    
    @Environment(\.scenePhase) private var scenePhase
    
    var isEditing: Bool {
        $editMode.wrappedValue.isEditing == true
    }

    let saveAction: ()->Void
    
    
    var body: some View {
        NavigationStack{
            List {
                ForEach ($otpList) { o in
                    let _ = isEditing
                    OTPRowView(otpItem: o, otpcolor: o.otpColor, otpLabel: o.issuer, otpCounter: o.counter, showCopyToast: $showCopyToast)
                    .swipeActions {
                        Button(
                            action: {
                                self.itemToDelete = o.wrappedValue
                                confirmationShown = true
                            }
                        ) {
                            Image(systemName: "trash")
                        }
                        .tint(.red)
                    }
                    .confirmationDialog(
                        "Are you sure you want to delete this key? You cannot undo this action.",
                        isPresented: $confirmationShown,
                        titleVisibility: .visible
                    ) {
                        Button(
                            "Delete",
                            role: .destructive
                        ) {
                            withAnimation {
                                deleteItem(self.itemToDelete)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteRow)
                .onMove(perform: isEditing ? relocate : nil)
            }
            
            .navigationTitle("Keys")
            .toolbar{
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                        .simultaneousGesture(TapGesture().onEnded {
                            saveAction()
                        })
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: {
                            showingAdd.toggle()
                        }) {
                            Label("Add by QR Code", systemImage: "qrcode.viewfinder")
                        }

                        Button(action: {
                            showingManualAdd.toggle()
                        }) {
                            Label("Add Manually", systemImage: "plus")
                        }
                    }
                    label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .toast(isPresenting: $showCopyToast){
                AlertToast(displayMode: .alert, type: .regular, title: "Code copied to clipboard!")
            }
            .environment(\.editMode, $editMode)
            .navigationDestination(isPresented: $showingAdd) {
                QRAddView(otpItems: $otpList)
            }
            .navigationDestination(isPresented: $showingManualAdd) {
                OTPManualAddView(otpList: $otpList)
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
    
    func relocate(from source: IndexSet, to destination: Int) {
        otpList.move(fromOffsets: source, toOffset: destination)
    }
    
    func deleteItem(_ item: OTPItem?) {
        guard let item else { return }
        
        var index = -1
        for i in 0...(otpList.count - 1) {
            print(i)
            if (otpList[i].id == item.id) {
                index = i
                break
            }
        }
        if (index == -1) {
            return
        }
        otpList.remove(at: index)
    }
    
    func deleteRow(at indexSet: IndexSet) {
        self.itemToDelete = nil
        confirmationShown = true
    }
}

struct OTPRowView: View {
    @Binding var otpItem: OTPItem
    @Binding var otpcolor: Color
    @Binding var otpLabel: String
    @Binding var otpCounter: Int
    @Binding var showCopyToast: Bool
    
    @State private var isDetailActive = false
    @State private var showingDeleteAlert = false
    
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
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(otpList: .constant([
            try! OTPItem("otpauth://totp/admin@dws.rip?secret=JBSWY3DPEHPK3PXP&issuer=Email%20(Work)&algorithm=SHA1&period=30"),
            try! OTPItem("otpauth://totp/admin@dws.rip?secret=JBSWY3DPEHPK3PXQ&issuer=AWS256&algorithm=SHA256&digits=8&period=30"),
            try! OTPItem("otpauth://totp/admin@dws.rip?secret=JBSWY3DPEHPK3PXR&issuer=AWS512&algorithm=SHA512&digits=6&period=30"),
            try! OTPItem("otpauth://totp/admin@dws.rip?secret=JBSWY3DPEHPK3PXS&issuer=AWS512&algorithm=SHA512&digits=6&period=45"),
            try! OTPItem("otpauth://hotp/admin@dws.rip?secret=JBSWY3DPEHPK3PXT&issuer=AWS512&digits=6&period=45"),
            try! OTPItem("otpauth://hotp/admin@dws.rip?secret=JBSWY3DPEHPK3PXU&issuer=AWS256&algorithm=SHA256&digits=6&period=45&counter=1"),
            try! OTPItem("otpauth://hotp/admin@dws.rip?secret=JBSWY3DPEHPK3PXV&issuer=AWS512&algorithm=SHA512&digits=8&period=45&counter=10"),
        ]), saveAction: {})
    }
}
