//
//  AudioItemEventProducer.swift
//  AudioPlayer
//
//  Created by Dionisis Karatzas on 20/9/22.
//  Copyright © 2022 Niosoft. All rights reserved.
//

import Combine
import Foundation

// MARK: - PlayerEventProducer

/// An `AudioItemEventProducer` generates event when a property of an `AudioItem` has changed.
class AudioItemEventProducer: EventProducer {
    /// An `AudioItemEvent` gets generated by `AudioItemEventProducer` when a property of `AudioItem` changes.
    ///
    /// - updatedArtist: `artist` was updated.
    /// - updatedTitle: `title` was updated.
    /// - updatedAlbum: `album` was updated.
    /// - updatedTrackCount: `trackCount` was updated.
    /// - updatedTrackNumber: `trackNumber` was updated.
    /// - updatedArtwork: `artwork` was updated.
    enum AudioItemEvent: String, Event {
        case updatedArtist = "artist"
        case updatedTitle = "title"
        case updatedAlbum = "album"
        case updatedTrackCount = "trackCount"
        case updatedTrackNumber = "trackNumber"
        case updatedArtwork = "artwork"
    }

    /// The player to produce events with.
    ///
    /// Note that setting it has the same result as calling `stopProducingEvents`.
    var item: AudioItem? {
        willSet {
            stopProducingEvents()
        }
    }

    /// The listener that will be alerted a new event occured.
    weak var eventListener: EventListener?

    /// A boolean value indicating whether we're currently listening to events on the player.
    private var listening = false

    private var cancellableBag = Set<AnyCancellable>()

    /// Stops producing events on deinitialization.
    deinit {
        stopProducingEvents()
    }

    /// Starts listening to the player events.
    func startProducingEvents() {
        guard let item = item, !listening else {
            return
        }

        // Observe AudioItem properties
        item.$artist.dropFirst().sink { _ in self.eventListener?.onEvent(AudioItemEvent.updatedArtist, generetedBy: self) }.store(in: &cancellableBag)
        item.$title.dropFirst().sink { _ in self.eventListener?.onEvent(AudioItemEvent.updatedTitle, generetedBy: self) }.store(in: &cancellableBag)
        item.$album.dropFirst().sink { _ in self.eventListener?.onEvent(AudioItemEvent.updatedAlbum, generetedBy: self) }.store(in: &cancellableBag)
        item.$trackCount.dropFirst().sink { _ in self.eventListener?.onEvent(AudioItemEvent.updatedTrackCount, generetedBy: self) }.store(in: &cancellableBag)
        item.$trackNumber.dropFirst().sink { _ in self.eventListener?.onEvent(AudioItemEvent.updatedTrackNumber, generetedBy: self) }.store(in: &cancellableBag)
        item.$artwork.dropFirst().sink { _ in self.eventListener?.onEvent(AudioItemEvent.updatedArtwork, generetedBy: self) }.store(in: &cancellableBag)

        listening = true
    }

    /// Stops listening to the player events.
    func stopProducingEvents() {
        // Clear AudioItem observers
        cancellableBag.removeAll()

        listening = false
    }
}
