//
//  EpisodeDetail.swift
//  Secret Peas
//
//  Created by Elizabeth Berry on 10/1/20.
//

import AVFoundation
import FeedKit
import SwiftUI

struct EpisodeDetail: View {
    @EnvironmentObject var audioSessionManager: AudioSessionManager
    
    var podcast: Podcast
    var episodeData: RSSFeedItem?
    
    var mp3File: URL
        
    @State var sigUrl: String = ""
    
    @State var showAlert: Bool = false
    @State var verificationSuccess: Bool = false
    
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    
    @State var showKeyManager: Bool = false

    var body: some View {
        let sigLink = EpisodeDetail.findSignatureLink(content: episodeData?.content?.contentEncoded)
        return AnyView(
            ScrollView {
                VStack(alignment: .leading) {
                    GroupBox {
                        Mp3Player(fileTitle: episodeData?.title, isNowPlaying: mp3File == audioSessionManager.nowPlaying.fileUrl).alert(isPresented: $showErrorAlert, content: {
                            Alert(title: Text("Error Occurred"), message: Text(errorMessage))
                        })
                    }
                    GroupBox(label: Label("Signature Verification", systemImage: "signature")) {
                        HStack {
                            TextField("Signature URL", text: $sigUrl)
                            Button("Submit", action: {
                                submitSignature()
                            })
                        }.padding(.bottom)
                        Button("Autofill", action: {
                            sigUrl = sigLink ?? sigUrl
                        }).disabled(sigLink == nil)
                    }
            
                    Spacer()
                    GroupBox(label: Label("Show Notes", systemImage: "note.text")) {
                        ShowNotes(showNotesString: episodeData?.content?.contentEncoded ?? "").frame(height: 300)
                    }
                }.alert(isPresented: $showAlert, content: {
                    switch verificationSuccess {
                    case true:
                        return Alert(title: Text("Verification Success!"), message: Text("This episode was successfully verified against its signature! It is probably not a deep-fake."))
                    case false:
                        return Alert(title: Text("Verification Failure"), message: Text("This episode failed the verification against the supplied signature. Must be a deep-fake; there's no other alternative explaination."))
                    }
                })
                    .padding()
                    .navigationBarTitle(Text(episodeData?.title ?? "[no title]"), displayMode: .inline)
            })
    }

    private func submitSignature() {
        guard podcast.key != nil else {
            print("public key not set")
            return
        }
    
        if sigUrl != "" {
            let verifier = SigVerify(
                mp3Url: mp3File,
                sigUrl: URL(string: sigUrl)!,
                keyData: podcast.key!
            )
            do {
                verificationSuccess = try verifier.verify()
                showAlert.toggle()
            } catch Downloader.DownloadError.networkConnectionError {
                errorMessage = "Could not verify signature; cannot connect to the internet."
                showErrorAlert = true
            } catch {
                errorMessage = "Unknown error: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
    }
    
    /**
     searches through the show notes of the episode for an anchor (<a>) tag that contains the string ‘rel=“signature”'.
     finds first instance.
     
     - Parameters:
     - content is the string representing the html of the show notes
     
     - Returns: the link to the signature file if successful. Returns nil if not.
     */
    static func findSignatureLink(content: String?) -> String? {
        guard let content = content else {
            return nil
        }
        
        let range = NSRange(content.startIndex ..< content.endIndex, in: content)
        
        let pattern = #"(<a.*href=\"(?<link1>(.*))\".*rel=\"signature\".*>)|(<a.*rel=\"signature\".*href=\"(?<link2>(.*))\".*>)"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        if let match = regex.firstMatch(in: content, options: [], range: range) {
            let link1Range = match.range(withName: "link1")
            let link2Range = match.range(withName: "link2")
            
            let retVar: NSRange? = {
                switch (link1Range.location, link2Range.location) {
                case (NSNotFound, NSNotFound): return nil
                case (NSNotFound, _): return link2Range
                case (_, _): return link1Range
                }
            }()
            
            if retVar == nil {
                return nil
            }
            
            let finalrange = Range(retVar!, in: content)!
            return "\(content[finalrange])"
        }
        return nil
    }
}

 struct EpisodeDetail_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

        let podcast = Podcast(context: context)
        
        return NavigationView {
            EpisodeDetail(podcast: podcast, mp3File: URL(string: "https://berrygood.website")!).environmentObject(AudioSessionManager())
        }
    }
 }
