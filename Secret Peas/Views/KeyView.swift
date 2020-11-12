//
//  KeyView.swift
//  Secret Peas
//
//  Created by Elizabeth Berry on 10/2/20.
//

import CoreData
import ObjectivePGP
import SwiftUI
import UniformTypeIdentifiers

struct KeyView: View {
    // MARK: Internal

    enum AddMethod {
        // 2 methods of importing:
        //      - by url
        //      - by text input (copy and paste)
        case URL
        case Text
    }

    @Environment(\.managedObjectContext) var managedObjectContext
    
    @Binding var showKeyView: Bool
    
    @State var podcast: Podcast

    var body: some View {
        if podcast.key == nil {
            // view for adding a key
            VStack(alignment: .leading) {
                Text("Add a Key By:")
                Picker("Add a Key By:", selection: $addPickerValue, content: {
                    Text("URL").tag(AddMethod.URL)
                    Text("Text Input").tag(AddMethod.Text)
                })
                    .pickerStyle(SegmentedPickerStyle()).padding(.bottom, 20.0)
                switch addPickerValue {
                case AddMethod.URL:
                    TextField("https://...", text: $addURLValue).textFieldStyle(RoundedBorderTextFieldStyle())
                    HStack {
                        Spacer()
                        Button("Save", action: {
                            if !addURLValue.isEmpty {
                                let download = downloadKey()
                                guard download != nil else {
                                    print("downloaded key is empty")
                                    return
                                }
                                saveKey(data: download!)
                            }
                            
                        })
                            .padding([.top, .trailing], 20.0)
                    }
                case AddMethod.Text:
                    ZStack {
                        // Begin Placeholder Hack
                        if addTextValue.isEmpty {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Paste the Key Here").multilineTextAlignment(.center).padding([.top, .leading], 9.0)
                                    Spacer()
                                }
                                Spacer()
                            }
                        }
                        // End Placeholder Hack
                        TextEditor(text: $addTextValue).border(Color.gray, width: 1).opacity(addTextValue.isEmpty ? 0.25 : 1)
                    }
                    HStack {
                        Spacer()
                        Button("Save", action: {
                            if !addTextValue.isEmpty {
                                saveKey(data: Data(addTextValue.utf8))
                            }
                            print("save key")
                        })
                            .padding([.top, .trailing], 20.0)
                    }
                }
                Spacer()
            }.padding()
                .alert(isPresented: $showErrorAlert, content: {
                    Alert(title: Text("Error Occurred"), message: Text(errorMessage))
                })
        } else {
            // verify key information
            VStack(alignment: .leading) {
                Text("KeyID:").bold()
                Text(getKeyId() ?? "[no key data]")
                HStack {
                    Spacer()
                    Button("Delete Key", action: {
                        deleteKey()
                    })
                        .padding([.top, .trailing], 20.0)
                        .accentColor(.red)
                }
                Spacer()
            }.padding()
        }
    }

    func getKeyId() -> String? {
        do {
            let keyID = try ObjectivePGP.readKeys(from: podcast.key!)
            return keyID.first!.keyID.longIdentifier
        } catch {
            print("could not interprent key data")
            return nil
        }
    }
    
    func downloadKey() -> Data? {
        var returnData: Data?
        let group = DispatchGroup()
        group.enter()
        do {
            try Downloader.load(url: URL(string: addURLValue)!, completion: { data in
                returnData = data
                group.leave()
            })
        } catch Downloader.DownloadError.networkConnectionError {
            errorMessage = "You are not connected to the internet."
            showErrorAlert = true
            group.leave()
        } catch {
            errorMessage = "An unknown error occurred."
            showErrorAlert = true
            print(error.localizedDescription)
            group.leave()
        }
        group.wait()
        return returnData
    }
    
    func saveKey(data: Data) {
        var keyData = Data()
        do {
            var key = try ObjectivePGP.readKeys(from: data)
            key = [key.first!]
            keyData = ObjectivePGP.defaultKeyring.export(key: key.first!, armored: false)!
        } catch {
            errorMessage = "Error: the given key is invalid."
            showErrorAlert = true
            return
        }
        
        podcast.key = keyData
        do {
            try managedObjectContext.save()
            showKeyView = false
        } catch {
            errorMessage = "Error saving the key data to the database."
            showErrorAlert = true
        }
    }
    
    func deleteKey() {
        podcast.key = nil
        do {
            try managedObjectContext.save()
            showKeyView = false
        } catch {
            print("core data error")
        }
    }
    
    // MARK: Private

    @State private var addPickerValue = AddMethod.URL
    @State private var addURLValue: String = ""
    @State private var addTextValue: String = ""

    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false
}

// struct KeyView_Previews: PreviewProvider {
//    @Environment(\.managedObjectContext) var managedObjectContext
//
//    static var previews: some View {
//        KeyView(showKeyView: $showKeyView, podcast: Podcast())
//    }
// }
