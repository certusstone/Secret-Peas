//
//  AllShowsView.swift
//  Secret Peas
//
//  Created by Elizabeth Berry on 10/2/20.
//

import CoreData
import ObjectivePGP
import SwiftUI

struct AllShowsView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var audioSessionManager: AudioSessionManager

    @FetchRequest(entity: Podcast.entity(),
                  sortDescriptors: [
                      NSSortDescriptor(keyPath: \Podcast.name, ascending: true)
                  ]) var podcasts: FetchedResults<Podcast>

    @State private var showAddPodcastView: Bool = false
    @State private var showAboutView: Bool = false

    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        updateFeeds()
        return ZStack {
            NavigationView {
                List {
                    if podcasts.count <= 0 {
                        Text("No podcasts yet! Add one!")
                    }
                    ForEach(podcasts, content: { (podcast: Podcast) in
                        NavigationLink(
                            destination: ShowView(podcast: podcast),
                            label: {
                                Text(podcast.name ?? "[no title]")
                            }
                        )
                    }).onDelete(perform: removePodcast)
                }.listStyle(PlainListStyle())
                    .navigationTitle("Podcasts")
                    .navigationBarItems(leading: Button("About", action: {
                        showAboutView = true
                    }),
                    trailing: Button("Add", action: {
                        showAddPodcastView = true
                    }))
            }
            .sheet(isPresented: $showAddPodcastView, content: {
                AddPodcastView(showCurrentView: $showAddPodcastView)
            })
            SwipeableBox(content: Mp3Player(isNowPlaying: true))
                .onReceive(audioSessionManager.audioTimer, perform: { _ in
                    audioSessionManager.updateCurrentTime()
                })
                .sheet(isPresented: $showAboutView, content: {
                    AboutView()
                })
        }.alert(isPresented: $showErrorAlert, content: {
            Alert(title: Text("An Error Occurred"), message: Text(errorMessage))
        })
    }

    private func removePodcast(at offsets: IndexSet) {
        for index in offsets {
            let podcast = podcasts[index]

            // delete any downloads associated with this show
            let feedInterface = FeedInterface(url: URL(string: podcast.url!)!)
            if let feed = feedInterface.feed { // if the feed is invalid, there cannot be any downloads associated
                for episode in feed.items ?? [] {
                    let mp3link = URL(string: (episode.enclosure?.attributes?.url)!)!
                    guard let podID = episode.guid?.value?.replacingOccurrences(of: "/", with: "_") else {
                        errorMessage = "Error removing downloaded file. Could not locate the file."
                        showErrorAlert = true
                        return
                    }
                    let mp3file = try? Downloader.mp3Path(downloadLink: mp3link, podID: podID)
                    if mp3file != nil {
                        do {
                            try Downloader.remove(url: mp3file!)
                        } catch {
                            errorMessage = "Error removing a downloaded file. \(error.localizedDescription)"
                            showErrorAlert = true
                            return
                        }
                    } else {
                        errorMessage = "Error removing a downloaded file. Could not locate the file."
                        showErrorAlert = true
                        return
                    }
                }
            }
            managedObjectContext.delete(podcast)
        }
        do {
            try managedObjectContext.save()
        } catch {
            errorMessage = "Error saving changes: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }

    private func updateFeeds() {
        for podcast in podcasts {
            if podcast.lastUpdated == nil || Date().timeIntervalSince(podcast.lastUpdated!) > 24 * 60 * 60 { // update the feed if it's been more than 24 hours since last update
                do { try FeedInterface.updateFeed(url: URL(string: podcast.url!)!) }
                catch Downloader.DownloadError.networkConnectionError {
                    // not connected to the internet; don't try to download.
                } catch FeedInterface.FeedError.DownloadError {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        errorMessage = "There was an error downloading feed data for \(podcast.name ?? "one of your podcasts")."
                        showErrorAlert = true
                    }
                } catch FeedInterface.FeedError.CoreDataError {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        errorMessage = "There was an error storing new feed data for \(podcast.name ?? "one of your podcasts")."
                        showErrorAlert = true
                    }
                } catch {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        errorMessage = "There was an error updating the feed data for \(podcast.name ?? "one of your podcasts")."
                        showErrorAlert = true
                    }
                    print("Unknown Error: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct AllShowsView_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        AllShowsView()
            .environment(\.managedObjectContext, context)
            .environmentObject(AudioSessionManager())
    }
}
