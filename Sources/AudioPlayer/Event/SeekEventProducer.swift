//
//  SeekEventProducer.swift
//  AudioPlayer
//
//  Created by Dionisis Karatzas on 20/9/22.
//  Copyright © 2022 Niosoft. All rights reserved.
//

import Foundation

/// A `SeekEventProducer` generates `SeekEvent`s when it's time to seek on the stream.
class SeekEventProducer: EventProducer {
    /// `SeekEvent` is an event generated by `SeekEventProducer`.
    ///
    /// - seekBackward: The event describes a seek backward in time.
    /// - seekForward: The event describes a seek forward in time.
    enum SeekEvent: Event {
        case seekBackward
        case seekForward
    }

    /// The timer used to generate events.
    private var timer: Timer?

    /// The listener that will be alerted a new event occured.
    weak var eventListener: EventListener?

    /// A boolean value indicating whether we're currently producing events or not.
    private var listening = false

    /// The delay to wait before cancelling last retry and retrying. Default value is 10 seconds.
    var intervalBetweenEvents = TimeInterval(10)

    /// A boolean value indicating whether the producer should generate backward or forward events.
    var isBackward = false

    /// Stops producing events on deinitialization.
    deinit {
        stopProducingEvents()
    }

    /// Starts listening to the player events.
    func startProducingEvents() {
        guard !listening else {
            return
        }

        // Creates a new timer for next retry
        restartTimer()

        // Saving that we're currently listening
        listening = true
    }

    /// Stops listening to the player events.
    func stopProducingEvents() {
        guard listening else {
            return
        }

        timer?.invalidate()
        timer = nil

        // Saving that we're not listening anymore
        listening = false
    }

    /// Stops the current timer if any and restart a new one.
    private func restartTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: intervalBetweenEvents, repeats: true, block: {[weak self] _ in
            self?.timerHandler()
        })
    }

    /// The retry timer ticked.
    ///
    /// - Parameter _: The timer.
    fileprivate func timerHandler() {
        eventListener?.onEvent(isBackward ? SeekEvent.seekBackward : .seekForward, generetedBy: self)
    }
}
