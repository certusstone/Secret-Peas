//
//  AudioSessionManager.swift
//  Secret Peas
//
//  Created by Elizabeth Berry on 10/14/20.
//

import AVFoundation
import Foundation
import MediaPlayer
import SwiftUI

class AudioSessionManager: ObservableObject {

    init() {}

    // MARK: Internal

    class Mp3Data: ObservableObject {
        @Published var duration: Double = 0.0
        @Published var currentTime: Double = 0.0
        @Published var fileUrl: URL?
        @Published var fileTitle: String?
        @Published var artwork: Image?
        @Published var playing: Bool = false

        func setData(url: URL, fileTitle: String?, artwork: Image?) throws {
            fileUrl = url
            self.fileTitle = fileTitle
            self.artwork = artwork
            guard Downloader.isDownloaded(url: url) else {
                throw Downloader.DownloadError.fileSystemError(description: "Preview file is a remote file. Cannot get data.")
            }
            do {
                let tempPlayer = try AVAudioPlayer(contentsOf: url)
                duration = tempPlayer.duration
                currentTime = tempPlayer.currentTime
            } catch {
                throw Downloader.DownloadError.fileSystemError(description: "Preview file could not be read. From file system.")
            }
        }
        
        func setData(url: URL) throws {
            try setData(url: url, fileTitle: nil, artwork: nil)
        }
    }

    var nowPlaying = Mp3Data()
    var previewData = Mp3Data()
    
    var audioSession: AVAudioSession?
    var player: AVAudioPlayer?
    
    let audioTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    func updateCurrentTime() {
        if nowPlaying.currentTime != player?.currentTime {
            nowPlaying.currentTime = player?.currentTime ?? 0.0
        }
    }
    
    func setPreview(url: URL) throws {
        try previewData.setData(url: url)
    }
    
    func setNowPlaying(url: URL, fileTitle: String?, artwork: Image?) throws {
        if audioSession == nil {
            prepareAudio()
            setupRemoteTransportControls()
        }
        if playerIsSet() {
            player!.stop()
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
        } catch let playerError {
            throw Downloader.DownloadError.fileSystemError(description: "Error setting audio player: \(playerError.localizedDescription)")
        }
        guard playerIsSet() else {
            throw Downloader.DownloadError.fileSystemError(description: "Error setting audio player.")
        }
        
        try nowPlaying.setData(url: url, fileTitle: fileTitle, artwork: artwork)
        
        setInfoCenter()
    }
    
    func adjustCurrentTime(isNowPlaying: Bool, currentTime: Double) {
        if isNowPlaying {
            nowPlaying.currentTime = currentTime
            player?.currentTime = currentTime
        } else {
            previewData.currentTime = currentTime
        }
    }
    
    func play() {
        guard audioSession != nil, playerIsSet(), nowPlaying.fileUrl != nil else {
            print("tried to play before player was set or nowPlaying was set")
            return
        }
        
        player!.play()
        nowPlaying.playing = player!.isPlaying
    }
    
    func pause() {
        guard playerIsSet() else {
            print("error tried to pause without player being set")
            return
        }
        player!.pause()
        nowPlaying.playing = player!.isPlaying
    }
    
    func rewind(seconds: Int) {
        guard playerIsSet() else {
            print("error tried to rewind without player being set")
            return
        }
        player!.currentTime -= Double(seconds)
        nowPlaying.currentTime = player!.currentTime.magnitude
    }
    
    func fastforward(seconds: Int) {
        guard playerIsSet() else {
            print("error tried to fast forward without player being set")
            return
        }
        player!.currentTime += Double(seconds)
        nowPlaying.currentTime = player!.currentTime.magnitude
    }

    // MARK: Private

    private func playerIsSet() -> Bool {
        guard let player = player else {
            return false
        }
        return player.url != nil || player.data != nil
    }
    
    private func prepareAudio() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession!.setCategory(AVAudioSession.Category.playback, mode: .default, options: [.allowAirPlay])
            try audioSession!.setActive(true, options: [])
        } catch let sessionError {
            print("error setting up audio session: \(sessionError.localizedDescription)")
            return
        }
    }
    
    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [NSNumber(integerLiteral: 30)]
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(integerLiteral: 30)]
        commandCenter.changePlaybackPositionCommand.isEnabled = true

        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [unowned self] _ in
            if self.player!.isPlaying == false {
                self.player!.play()
                self.nowPlaying.playing = true
                return .success
            }
            return .commandFailed
        }

        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [unowned self] _ in
            if self.player!.isPlaying {
                self.player!.pause()
                self.nowPlaying.playing = false
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.skipBackwardCommand.addTarget { [unowned self] _ in
            self.rewind(seconds: 30)
            var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
            nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = player!.currentTime
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            return .success
        }
        
        commandCenter.skipForwardCommand.addTarget { [unowned self] _ in
            self.fastforward(seconds: 30)
            var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
            nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = player!.currentTime
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [unowned self] event in
            let event = event as! MPChangePlaybackPositionCommandEvent
            self.adjustCurrentTime(isNowPlaying: true, currentTime: event.positionTime)

            var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
            nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = player!.currentTime
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

            return .success
        }
        
    }
    
    private func setInfoCenter() {
        // Define Now Playing Info
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = nowPlaying.fileTitle ?? "Podcast"

        // TODO: album art
        // nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: <#T##UIImage#>)
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player!.currentTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player!.duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player!.rate

        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
