//
//  SigVerify.swift
//  Secret Peas
//
//  Created by Elizabeth Berry on 10/1/20.
//

import Foundation
import ObjectivePGP

class SigVerify {
    var mp3Url:URL
    var sigUrl:URL
    var keyData:Data
    
    init(mp3Url:URL, sigUrl:URL, keyData:Data) {
        self.mp3Url = mp3Url
        self.sigUrl = sigUrl
        self.keyData = keyData
    }
    
    func verify() throws -> Bool {
        var sigData:Data?
        var key:Key?
        
        let group = DispatchGroup()
        group.enter() // sig
        
        do {
            try Downloader.load(url: sigUrl, completion: { data in
                sigData = data
                group.leave()
            })
        } catch let error {
            group.leave()
            throw error
        }
        
        group.wait()

        guard sigData != nil else {
            print("sig data is unavailable")
            return false
        }
        
        do {
            key = try ObjectivePGP.readKeys(from: keyData).first
        } catch {
            print("could not read keys from data")
        }
        
        guard key != nil else {
            print("key could not be found")
            return false
        }
        
        do {
            try ObjectivePGP.verify(Data(contentsOf: mp3Url), withSignature: sigData!, using: [key!])
            return true
        } catch {
            print("signature could not be verified")
            return false
        }
    }
}
