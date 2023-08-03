//
//  OTPQRImageAddView.swift
//  Sesame
//
//  Created by Tanishq Dubey on 7/27/23.
//

import SwiftUI
import PhotosUI
import GAuthSwiftParser

struct OTPQRImageAddView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @Binding var otpItems: [OTPItem]
    
    @State private var selecteditem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var showingError = false
    @State private var addError: String = ""
    
    var body: some View {
        VStack{
            Spacer()
            if let selectedImageData,
               let uiImage = UIImage(data: selectedImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                    .frame(maxWidth: 300)
            }
            Spacer()
            PhotosPicker(
                selection: $selecteditem,
                matching: .images,
                photoLibrary: .shared()) {
                    if selectedImageData != nil {
                        Text("Change Photo")
                    } else {
                        Text("Select a Photo")
                    }
                }
                .onChange(of: selecteditem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            selectedImageData = data
                        }
                    }
                }
                .padding(EdgeInsets(top: 5, leading: 5, bottom: 20, trailing: 5))
            Button(action: {
                do {
                    let uiImage = UIImage(data: selectedImageData!)
                    if let features = detectQRCode(uiImage), !features.isEmpty {
                        if features.count == 1 {
                            for case let row as CIQRCodeFeature in features {
                                let urldata = row.messageString ?? "nil"
                                if urldata == "nil" {
                                    addError = "Could not extract OTP data from QR Code"
                                    showingError.toggle()
                                } else if urldata.starts(with: "otpauth-migration") {
                                    let data = GAuthSwiftParser.getAccounts(code: urldata)
                                    for otp in data {
                                        let item = try OTPItem(otp.getLink())
                                        otpItems.append(item)
                                    }
                                } else {
                                    let item = try OTPItem(urldata)
                                    otpItems.append(item)
                                }
                                self.presentationMode.wrappedValue.dismiss()
                            }
                        } else {
                            addError = "Could not extract OTP data from QR Code"
                            showingError.toggle()
                        }
                    } else {
                        addError = "Could not find a QR code in the selected image"
                        showingError.toggle()
                    }
                } catch OTPError.malformedInput {
                    addError = "The OTP URL is malformed, please double check it"
                    showingError.toggle()
                } catch OTPError.parsingError {
                    addError = "There was an error parsing the OTP details"
                    showingError.toggle()
                } catch {
                    addError = "An unknown error has happened while adding the OTP code"
                    showingError.toggle()
                }

            }) {
                Text("Extract QR code from image")
            }.disabled(selectedImageData == nil)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 15, trailing: 0))
        }.alert(isPresented: $showingError) {
            Alert(
                title: Text("Could not add OTP"),
                message: Text(addError),
                dismissButton: .default(Text("OK"), action: {
                    self.presentationMode.wrappedValue.dismiss()
                })
            )
        }.navigationBarTitle("Add Via Image")
    }
    
    func detectQRCode(_ image: UIImage?) -> [CIFeature]? {
        if let image = image, let ciImage = CIImage.init(image: image) {
            var options: [String: Any]
            let context = CIContext()
            options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
            let qrDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: options)
            if ciImage.properties.keys.contains((kCGImagePropertyOrientation as String)) {
                options = [CIDetectorImageOrientation: ciImage.properties[(kCGImagePropertyOrientation as String)] ?? 1]
            } else {
                options = [CIDetectorImageOrientation: 1]
            }
            let features = qrDetector?.features(in: ciImage, options: options)
            return features
        }
        
        return nil
    }
}



#Preview {
        OTPQRImageAddView(otpItems: .constant([
            try! OTPItem("otpauth://totp/admin@dws.rip?secret=JBSWY3DPEHPK3PXP&issuer=AWS&algorithm=SHA1&period=30"),
            try! OTPItem("otpauth://totp/admin@dws.rip?secret=JBSWY3DPEHPK3PXQ&issuer=AWS256&algorithm=SHA256&digits=8&period=30"),
            try! OTPItem("otpauth://totp/admin@dws.rip?secret=JBSWY3DPEHPK3PXR&issuer=AWS512&algorithm=SHA512&digits=6&period=30"),
            try! OTPItem("otpauth://totp/admin@dws.rip?secret=JBSWY3DPEHPK3PXS&issuer=AWS512&algorithm=SHA512&digits=6&period=45"),
            try! OTPItem("otpauth://hotp/admin@dws.rip?secret=JBSWY3DPEHPK3PXT&issuer=AWS512&digits=6&period=45"),
            try! OTPItem("otpauth://hotp/admin@dws.rip?secret=JBSWY3DPEHPK3PXU&issuer=AWS256&algorithm=SHA256&digits=6&period=45&counter=1"),
            try! OTPItem("otpauth://hotp/admin@dws.rip?secret=JBSWY3DPEHPK3PXV&issuer=AWS512&algorithm=SHA512&digits=8&period=45&counter=10"),
        ]))
}
