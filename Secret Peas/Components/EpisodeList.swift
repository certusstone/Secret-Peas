//
//  EpisodeList.swift
//  Secret Peas
//
//  Created by Elizabeth Berry on 10/1/20.
//

import SwiftUI
import FeedKit

struct EpisodeList: View {
    @EnvironmentObject var audioSessionManager: AudioSessionManager

    var podcast:Podcast
        
    var body: some View {
        let feedInterface = FeedInterface(url: URL(string: podcast.url!)!)

        guard let feed = feedInterface.feed else {
            return AnyView(Text("failure: invalid feed"))
        }
    
        return AnyView(List {
            Text(feed.description ?? "[no description]").font(.callout).lineLimit(6)
            ForEach(feed.items ?? []) { (item:RSSFeedItem) in
                let mp3link = URL(string: (item.enclosure?.attributes?.url)!)!
                if let podID = item.guid?.value?.replacingOccurrences(of: "/", with: "_") {
                    let mp3file = try? Downloader.mp3Path(downloadLink: mp3link, podID: podID)
                    EpisodeRow(podcast: podcast, episodeData: item, mp3File: mp3file ?? mp3link)
                } else {
                    Text("[invalid item in feed]")
                }
            }
        })
    }
}


struct EpisodeList_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let podcast = Podcast(context: context)
        podcast.name = "Worrying Bugs"
        podcast.url = "https://superawesomecorp.com/worryingbugs/index.php/feed/podcast/"
        podcast.feedData = try! Data(contentsOf: URL(string: podcast.url!)!)
        return NavigationView {
            EpisodeList(podcast: podcast)
            .environment(\.managedObjectContext, context)
            .navigationTitle(podcast.name!)
        }
    }
}
