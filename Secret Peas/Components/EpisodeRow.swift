//
//  EpisodeRow.swift
//  Secret Peas
//
//  Created by Elizabeth Berry on 10/1/20.
//

import SwiftUI
import FeedKit

struct EpisodeRow: View {
    @EnvironmentObject var audioSessionManager: AudioSessionManager

    var podcast:Podcast
    var episodeData: RSSFeedItem?
    
    @State var mp3File:URL
    
    @State private var selection:URL?
    
    @State private var isDownloading: Bool = false
    
    @State private var showDeleteActionSheet: Bool  = false
    
    @State private var errorMessage:String = ""
    @State private var showErrorAlert: Bool = false
    
    var body: some View {
        let bindingSelection = Binding<URL?>(
        get: {
            self.selection
        }, set: {
            if $0 != nil {
                do {
                    try audioSessionManager.setPreview(url: $0!)
                } catch Downloader.DownloadError.fileSystemError(let description) {
                    errorMessage = "Error setting up next view. \(description)"
                    showErrorAlert = true
                    return
                } catch {
                    errorMessage = "Error setting up next view."
                    showErrorAlert = true
                    return
                }
            }
            self.selection = $0
            
        })
        return ZStack {
            HStack {
                Spacer()
                Button(action: {
                    downloadFile()
                }, label: {
                    switch (Downloader.isDownloaded(url: mp3File), isDownloading) {
                    case (false, false): Image(systemName: "icloud.and.arrow.down").foregroundColor(.blue)
                    case (false, true): ProgressView()
                    case (true, _): Image(systemName: "checkmark.icloud").foregroundColor(.gray)
                    }
                }).padding(Edge.Set.trailing, 15.0)
            }
            NavigationLink(destination: EpisodeDetail(podcast: podcast, episodeData: episodeData, mp3File: mp3File), tag: mp3File, selection: bindingSelection, label: {
                HStack(content: {
                    Text(episodeData?.title ?? "[no episode title]")
                    Spacer()
                })
            })
            .disabled(!Downloader.isDownloaded(url: mp3File))
            .onTapGesture { // workaround for long-press disallowing activating the navigation link with a tap on the label
                if Downloader.isDownloaded(url: mp3File), !isDownloading {
                    bindingSelection.wrappedValue = mp3File
                }
            }
            .onLongPressGesture {
                if Downloader.isDownloaded(url: mp3File), !isDownloading {
                    showDeleteActionSheet = true
                }
            }
        }
        .actionSheet(isPresented: $showDeleteActionSheet, content: {
            ActionSheet(title: Text("Delete?"),
                        message: Text("Are you sure you want to delete \(episodeData?.title ?? "this episode")?"),
                        buttons: [
                            .cancel(),
                            .destructive(Text("Delete")) {
                                removeFile()
                            }
                        ]
            )
        })
        .alert(isPresented: $showErrorAlert, content: {
            Alert(title: Text("Error Occurred"), message: Text(errorMessage))
        })
    }
    
    func downloadFile() {
        guard !Downloader.isDownloaded(url: mp3File), !isDownloading else {
            return
        }

        isDownloading = true
        guard let podID = episodeData?.guid?.value?.replacingOccurrences(of: "/", with: "_") else {
            errorMessage = "Could not downolad episode. The RSS feed is invalid."
            showErrorAlert = true
            isDownloading = false
            return
        }
        do {
            try Downloader.loadMp3(url: mp3File, podID: podID, completion: { fileUrl in
                isDownloading = false
                mp3File = fileUrl
            })
        } catch Downloader.DownloadError.networkConnectionError {
            errorMessage = "Could not download episode. Could not connect to the internet."
            showErrorAlert = true
            isDownloading = false
            return
        } catch let error {
            errorMessage = error.localizedDescription
            showErrorAlert = true
            isDownloading = false
            return
        }
    }
    
    func removeFile() {
        do {
            try Downloader.remove(url: mp3File)
            mp3File = URL(string: podcast.url!)!
        } catch Downloader.DownloadError.fileSystemError(let description) {
            errorMessage = "Error removing file: \(description)"
            showErrorAlert = true
        } catch let error {
            errorMessage = "Unknown error removing file."
            showErrorAlert = true
            print(error.localizedDescription)
        }
    }
    
}

//struct EpisodeRow_Previews: PreviewProvider {
//    static var previews: some View {
//        EpisodeRow(mp3File: URL(string: "https://superawesomecorp.com/worryingbugs/episodes/CommonlyDynamicBlases.mp3")!)
//    }
//}
