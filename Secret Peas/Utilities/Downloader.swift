//
//  Downloader.swift
//  Secret Peas
//
//  Created by Elizabeth Berry on 10/6/20.
//

import Foundation

class Downloader {
    enum DownloadError: Error {
        case urlConstructionError
        case networkConnectionError
        case unknownError(description: String)
        case fileSystemError(description: String)
    }

    static func isDownloaded(url: URL) -> Bool {
        return !(url.absoluteString.hasPrefix("http://") || url.absoluteString.hasPrefix("https://"))
    }

    class func mp3Path(downloadLink: URL, podID: String) throws -> URL? {
        do {
            let documentsURL = try
                FileManager.default.url(for: .documentDirectory,
                                        in: .userDomainMask,
                                        appropriateFor: nil,
                                        create: false)
            let savedURL = documentsURL.appendingPathComponent(podID).appendingPathExtension("mp3")
        
            return FileManager.default.fileExists(atPath: savedURL.path) ? savedURL : nil
        } catch {
            throw DownloadError.fileSystemError(description: "Could not locate user-documents directory")
        }
    }
    
    class func loadMp3(url: URL, podID: String, completion: @escaping (URL) -> ()) throws { // TODO: handle networking errors
        var savedURL: URL?
        
        let documentsURL = try // replace with mp3Path function
            FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
        savedURL = documentsURL.appendingPathComponent(podID).appendingPathExtension("mp3")
        
        guard savedURL != nil else {
            print("error constructing savedURL")
            throw DownloadError.urlConstructionError
        }
        
        guard Network.reachability.status != .unreachable else {
            throw DownloadError.networkConnectionError
        }
                    
        let downloadTask = URLSession.shared.downloadTask(with: url) {
            urlOrNil, _, _ in
            
            guard let fileURL = urlOrNil else { return }
            do {
                if FileManager.default.fileExists(atPath: savedURL!.path) { // overwrite file if it exists
                    try FileManager.default.removeItem(at: savedURL!)
                }
                try FileManager.default.moveItem(at: fileURL, to: savedURL!)
                completion(savedURL!)
            } catch {
                print("file error: \(error)")
            }
        }
        downloadTask.resume()
    }
    
    class func load(url: URL, to localUrl: URL, completion: @escaping () -> ()) throws { // TODO: handle networking errors
        guard Network.reachability.status != .unreachable else {
            throw DownloadError.networkConnectionError
        }
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let request = URLRequest(url: url)

        let task = session.downloadTask(with: request) { tempLocalUrl, response, error in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                // Success
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print("Success: \(statusCode)")
                }

                do {
                    if FileManager.default.fileExists(atPath: localUrl.path) { // overwrite file if it exists
                        try FileManager.default.removeItem(at: localUrl)
                    }
                    try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
                    completion()
                } catch let writeError {
                    print("error writing file \(localUrl) : \(writeError)")
                }

            } else {
                print("Failure: %@", error?.localizedDescription as Any)
            }
        }
        task.resume()
    }
    
    class func load(url: URL, completion: @escaping (Data) -> ()) throws { // TODO: handle networking errors
        guard Network.reachability.status != .unreachable else {
            throw DownloadError.networkConnectionError
        }
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let request = URLRequest(url: url)
        
        let task = session.downloadTask(with: request) { tempLocalUrl, response, error in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print("Success: \(statusCode)")
                }
                do {
                    completion(try Data(contentsOf: tempLocalUrl))
                } catch let dataError {
                    print("could not convert data: \(dataError)")
                }
            } else {
                print("Failure: \(error?.localizedDescription ?? "unknown error")")
            }
        }
        task.resume()
    }
    
    class func remove(url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw DownloadError.fileSystemError(description: "tried to remove file that does not exist")
        }
        
        do {
            try FileManager.default.removeItem(atPath: url.path)
        } catch let removeError {
            throw DownloadError.fileSystemError(description: "unknown error removing file at \(url.path). \(removeError.localizedDescription)")
        }
    }
}
