//
//  Mp3Player.swift
//  Secret Peas
//
//  Created by Elizabeth Berry on 10/6/20.
//

import AVFoundation
import SwiftUI

struct Mp3Player: View {
    @EnvironmentObject var audioSessionManager: AudioSessionManager
    @EnvironmentObject var nowPlaying: AudioSessionManager.Mp3Data

    @State var fileTitle: String?
    @State var artwork: Image?

    @State private var showAlertView: Bool = false
    @State private var errorMessage: String = ""

    @State var isNowPlaying: Bool

    var body: some View {
        VStack {
            Mp3TimingElements(isNowPlaying: isNowPlaying).padding(.bottom)
            HStack {
                Spacer()
                Button(action: {
                    audioSessionManager.rewind(seconds: 30)
                }) {
                        Image(systemName: "gobackward.30")
                }.disabled(!isNowPlaying)
                Spacer()
                Button(action: {
                    playPause()
                }) {
                        if isNowPlaying, nowPlaying.playing {
                            Image(systemName: "pause.fill")
                        } else {
                            Image(systemName: "play.fill")
                        }
                }
                Spacer()
                Button(action: {
                    audioSessionManager.fastforward(seconds: 30)
                }) {
                        Image(systemName: "goforward.30")
                }.disabled(!isNowPlaying)
                Spacer()
            }
            .alert(isPresented: $showAlertView, content: {
                Alert(title: Text("An Error has Occurred"), message: Text(errorMessage))
            })
        }.padding(.bottom)
    }

    private func playPause() {
        switch (isNowPlaying, nowPlaying.playing) {
        case (true, true): audioSessionManager.pause()
        case (true, false): audioSessionManager.play()
        case (false, _):
            guard let fileURL = isNowPlaying ? nowPlaying.fileUrl : audioSessionManager.previewData.fileUrl else {
                return
            }
            do {
                try audioSessionManager.setNowPlaying(url: fileURL, fileTitle: fileTitle, artwork: artwork)
            } catch let Downloader.DownloadError.fileSystemError(description) {
                errorMessage = description
                showAlertView = true
                return
            } catch {
                errorMessage = "An error occurred while attempting to play this audio."
                showAlertView = true
                return
            }
            isNowPlaying = true
            audioSessionManager.play()
        }
    }
    
    static func secondsToTimeStamp(seconds: Int) -> String {
        guard seconds >= 0 else {
            return ""
        }

        let (hourInt, minInt, secInt) = (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
        var hourString: String, minString: String, secString: String

        if hourInt < 10 {
            hourString = "0\(hourInt)"
        } else {
            hourString = "\(hourInt)"
        }

        if minInt < 10 {
            minString = "0\(minInt)"
        } else {
            minString = "\(minInt)"
        }

        if secInt < 10 {
            secString = "0\(secInt)"
        } else {
            secString = "\(secInt)"
        }

        return "\(hourString):\(minString):\(secString)"
    }
}

struct Mp3TimingElements: View { // moved to a separate view for performance
    @EnvironmentObject var audioSessionManager: AudioSessionManager
    @EnvironmentObject var nowPlaying: AudioSessionManager.Mp3Data

    var isNowPlaying: Bool

    @State private var editing: Bool = false
    @State private var tempCurrentTime = 0.0

    var body: some View {
        let currentTime = isNowPlaying ? nowPlaying.currentTime : audioSessionManager.previewData.currentTime
        let duration = isNowPlaying ? nowPlaying.duration : audioSessionManager.previewData.duration
        let currentTimeWrapper = Binding(
            get: { () -> Double in
                if editing {
                    return tempCurrentTime
                } else {
                    return currentTime
                }
            },
            set: {
                tempCurrentTime = $0
                editing = true
            })

        let stringDuration = Mp3Player.secondsToTimeStamp(seconds: Int(duration))
        let stringCurrent = Mp3Player.secondsToTimeStamp(seconds: Int(currentTimeWrapper.wrappedValue))
        return HStack {
            Text("\(stringCurrent)").font(.caption)
            Slider(value: currentTimeWrapper, in: 0 ... duration, onEditingChanged: { _ in
                audioSessionManager.adjustCurrentTime(isNowPlaying: isNowPlaying, currentTime: tempCurrentTime)
                editing = false
            })
            Text("\(stringDuration)").font(.caption)
        }
    }
}

struct Mp3Player_Previews: PreviewProvider {
    static var previews: some View {
        GroupBox {
            Mp3Player(isNowPlaying: false)
                .environmentObject(AudioSessionManager()).padding()
        }.padding()
    }
}
