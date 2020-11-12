//
//  AddPodcastView.swift
//  Secret Peas
//
//  Created by Elizabeth Berry on 10/2/20.
//

import CoreData
import SwiftUI

struct AddPodcastView: View {
    @Environment(\.managedObjectContext) var managedObjectContext

    @State private var newPodcastUrl: String = ""

    @Binding var showCurrentView: Bool
    
    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            Text("Add Podcast by Feed URL:")
            TextField("https://...", text: $newPodcastUrl)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            HStack {
                Spacer()
                Button("Submit", action: {
                    addPodcast()
                })
                    .padding([.top, .trailing], 20.0)
            }
            Spacer()
        }.padding()
        .alert(isPresented: $showErrorAlert, content: {
            Alert(title: Text("Error Occurred"), message: Text(errorMessage))
        })
    }

    private func addPodcast() {
        // download feed data and store it in the database
        guard let safePodUrl = URL(string: newPodcastUrl) else {
            errorMessage = "Could not add podcast. URL is invalid."
            showErrorAlert = true
            return
        }
        
        do {
            try FeedInterface.addPodcast(url: safePodUrl)
        } catch Downloader.DownloadError.networkConnectionError {
            errorMessage = "Could not add podcast. Could not connect to the internet."
            showErrorAlert = true
            return
        } catch FeedInterface.FeedError.InvalidFeedError(let reason) {
            print("Error: \(String(describing: reason))")
            errorMessage = "There was an error parsing this podcast's feed."
            showErrorAlert = true
            return
        } catch FeedInterface.FeedError.DownloadError {
            errorMessage = "There was an error downloading this podcast's data."
            showErrorAlert = true
            return
        } catch FeedInterface.FeedError.CoreDataError {
            errorMessage = "There was an error adding this podcast to the database."
            showErrorAlert = true
            return
        } catch let error {
            print("Unknown Error: \(error.localizedDescription)")
            errorMessage = "An unknown error occurred."
            showErrorAlert = true
            return
        }

        showCurrentView = false
    }
}

struct AddPodcastView_Previews: PreviewProvider {
    static var previews: some View {
        AddPodcastView(showCurrentView: Binding<Bool>(get: {
            true
        }, set: { _ in }))
    }
}
