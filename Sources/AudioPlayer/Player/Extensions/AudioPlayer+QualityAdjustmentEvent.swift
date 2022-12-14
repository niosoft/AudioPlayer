//
//  AudioPlayer+QualityAdjustmentEvent.swift
//  AudioPlayer
//
//  Created by Dionisis Karatzas on 20/9/22.
//  Copyright © 2022 Niosoft. All rights reserved.
//

import AVFoundation

extension AudioPlayer {
    /// Handles quality adjustment events.
    ///
    /// - Parameters:
    ///   - producer: The event producer that generated the quality adjustment event.
    ///   - event: The quality adjustment event.
    func handleQualityEvent(from _: EventProducer,
                            with event: QualityAdjustmentEventProducer.QualityAdjustmentEvent)
    {
        // Early exit if user doesn't want to adjust quality
        guard adjustQualityAutomatically else {
            return
        }

        switch event {
        case .goDown:
            guard let quality = AudioQuality(rawValue: currentQuality.rawValue - 1) else {
                return
            }
            changeQuality(to: quality)

        case .goUp:
            guard let quality = AudioQuality(rawValue: currentQuality.rawValue + 1) else {
                return
            }
            changeQuality(to: quality)
        }
    }

    /// Changes quality of the stream if possible.
    ///
    /// - Parameter newQuality: The new quality.
    private func changeQuality(to newQuality: AudioQuality) {
        guard let url = currentItem?.soundURLs[newQuality] else {
            return
        }

        let cip = currentItemProgression
        let item = AVPlayerItem(url: url)
        updatePlayerItemForBufferingStrategy(item)

        qualityIsBeingChanged = true
        player?.replaceCurrentItem(with: item)
        if let cip = cip {
            // We can't call self.seek(to:) in here since the player is loading a new
            // item and `cip` is probably not in the seekableTimeRanges.
            player?.seek(to: CMTime(timeInterval: cip))
        }
        qualityIsBeingChanged = false

        currentQuality = newQuality
    }
}
