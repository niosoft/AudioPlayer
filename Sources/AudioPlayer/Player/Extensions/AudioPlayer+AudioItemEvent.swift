//
//  AudioPlayer+AudioItemEvent.swift
//  AudioPlayer
//
//  Created by Dionisis Karatzas on 20/9/22.
//  Copyright © 2022 Niosoft. All rights reserved.
//

extension AudioPlayer {
    /// Handles audio item events.
    ///
    /// - Parameters:
    ///   - producer: The event producer that generated the audio item event.
    ///   - event: The audio item event.
    func handleAudioItemEvent(from _: EventProducer, with _: AudioItemEventProducer.AudioItemEvent) {
        if setNowPlayingMetadata, let currentItem {
            let isLiveStream = !currentItem.highestQualityURL.url.ap_isOfflineURL
            let metadata = NowPlayableStaticMetadata(assetURL: currentItem.highestQualityURL.url, mediaType: .audio, isLiveStream: isLiveStream, title: currentItem.title, artist: currentItem.artist, artwork: currentItem.artwork, album: currentItem.album, trackCount: currentItem.trackCount, trackNumber: currentItem.trackNumber)
            nowPlayableService?.handleNowPlayableItemChange(metadata: metadata)
        }
    }
}
