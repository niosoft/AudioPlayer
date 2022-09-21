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
    func handleAudioItemEvent(from producer: EventProducer, with event: AudioItemEventProducer.AudioItemEvent) {
        updateNowPlayingInfoCenter()
    }
}
