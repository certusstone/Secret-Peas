//
//  ContentView.swift
//  Secret Peas
//
//  Created by Elizabeth Berry on 10/1/20.
//

import SwiftUI

struct ShowView: View {
    var podcast:Podcast
    
    @State var showKeyView = false
    
    var body: some View {
        let feedInterface = FeedInterface(url: URL(string: podcast.url!)!)
        EpisodeList(podcast: podcast)
            .navigationBarTitle(Text(feedInterface.feed?.title ?? "[no title]"))
            .navigationBarItems(trailing: Button("Key", action: {
                showKeyView.toggle()
            }).sheet(isPresented: $showKeyView, content: {
                KeyView(showKeyView: $showKeyView, podcast: podcast)
            }))
    }
}

struct ShowView_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let podcast = Podcast(context: context)
        podcast.name = "Worrying Bugs"
        podcast.url = "https://superawesomecorp.com/worryingbugs/index.php/feed/podcast/"
        podcast.feedData = try! Data(contentsOf: URL(string: podcast.url!)!)
        return NavigationView {
            ShowView(podcast: podcast)
        }
    }
}
