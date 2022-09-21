//
//  AudioPlayer+RetryEvent.swift
//  AudioPlayer
//
//  Created by Dionisis Karatzas on 20/9/22.
//  Copyright © 2022 Niosoft. All rights reserved.
//

import Foundation

extension AudioPlayer {
    /// Handles retry events.
    ///
    /// - Parameters:
    ///   - producer: The event producer that generated the retry event.
    ///   - event: The retry event.
    func handleRetryEvent(from producer: EventProducer, with event: RetryEventProducer.RetryEvent) {
        switch event {
        case .retryAvailable:
            retryOrPlayNext()

        case .retryFailed:
            state = .failed(.maximumRetryCountHit)
            producer.stopProducingEvents()
        }
    }
}
