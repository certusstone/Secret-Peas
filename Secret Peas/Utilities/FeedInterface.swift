//
//  FeedInterface.swift
//  Secret Peas
//
//  Created by Elizabeth Berry on 10/1/20.
//

import CoreData
import FeedKit
import Foundation
import UIKit

class FeedInterface {
    var url: URL?
    var feed: RSSFeed?
    
    enum FeedError: Error {
        case CoreDataError
        case InvalidFeedError(reason: String?)
        case DownloadError
    }
    
    init(url: URL) {
        var parseResult: Result<Feed, ParserError>

        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate
        else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Podcast")
        fetchRequest.predicate = NSPredicate(format: "url == %@", url.absoluteString)
        
        do {
            let podcast = try managedContext.fetch(fetchRequest).first as! Podcast // TODO: make this safer
            let parser = FeedParser(data: podcast.feedData ?? Data())
            parseResult = parser.parse()
        } catch {
            fatalError("core data error: \(error.localizedDescription)")
        }

        self.url = url
        switch parseResult {
        case .success(let tempFeed):
            switch tempFeed {
            case .rss(let tempFeed):
                feed = tempFeed
            default:
                print("Only RSS Feeds are Supported at this Time")
            }
        case .failure(let error):
            // TODO: make sure the user knows what went wrong
            print(error)
        }
    }
    
    static func updateFeed(url: URL) throws {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate
        else {
            throw FeedError.CoreDataError
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Podcast")
        fetchRequest.predicate = NSPredicate(format: "url == %@", url.absoluteString)
        
        guard let podcast = try managedContext.fetch(fetchRequest).first as? Podcast else {
            throw FeedError.CoreDataError // request could not be converted to a podcast data type -- usually because the url did not match any records
        }
        
        let feedData = try downloadFeedData(url: url)
        podcast.setValue(feedData, forKey: "feedData")
        podcast.lastUpdated = Date()
        try managedContext.save()
    }
    
    static private func downloadFeedData(url: URL) throws -> Data {
        var feedData:Data?
        let group = DispatchGroup()
        group.enter()
        
       try Downloader.load(url: url, completion: { tempData in
            feedData = tempData
            group.leave()
        })
        
        _ = group.wait(timeout: .now() + 10)
        
        guard let safeFeedData = feedData else {
            throw FeedError.DownloadError
        }
        
        return safeFeedData
    }
    
    static func addPodcast(url: URL) throws {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            throw FeedError.CoreDataError
        }
        
        let feedData = try downloadFeedData(url: url)
        
        let parser = FeedParser(data: feedData)
        let parseResult = parser.parse()
        
        switch parseResult {
        case .success(let tempFeed):
            switch tempFeed {
            case .rss(let tempFeed):
                guard tempFeed.title != nil else {
                    throw FeedError.InvalidFeedError(reason: "The Title of this Podcast Doesn't Exist")
                }
                
                let managedContext = appDelegate.persistentContainer.viewContext
                let newPod = Podcast(context: managedContext)
                newPod.name = tempFeed.title
                newPod.url = url.absoluteString
                newPod.feedData = feedData
                newPod.lastUpdated = Date()
                do {
                    try managedContext.save()
                } catch {
                    throw FeedError.CoreDataError
                }
            default:
                throw FeedError.InvalidFeedError(reason: "Only RSS feeds are supported at this time.")
            }
           
        case .failure(let failData):
            throw FeedError.InvalidFeedError(reason: "\(String(describing: failData.errorDescription)) \(String(describing: failData.failureReason)) \(String(describing: failData.recoverySuggestion))")
        }
    }
}

extension RSSFeedItem: Identifiable {}
