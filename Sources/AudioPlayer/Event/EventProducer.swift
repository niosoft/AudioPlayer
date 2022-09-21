//
//  EventProducer.swift
//  AudioPlayer
//
//  Created by Dionisis Karatzas on 20/9/22.
//  Copyright © 2022 Niosoft. All rights reserved.
//

import Foundation

/// An `Event` represents an event that can occur.
protocol Event {}

/// An `EventListener` listens to events generated by a `PlayerEventProducer`.
protocol EventListener: AnyObject {
    /// Called when an event occurs.
    ///
    /// - Parameters:
    ///   - event: The event that occured.
    ///   - eventProducer: The producer at the root of the event.
    func onEvent(_ event: Event, generetedBy eventProducer: EventProducer)
}

/// An `EventProducer` serves the purpose of producing events over time.
protocol EventProducer: AnyObject {
    /// The listener that will be alerted a new event occured.
    var eventListener: EventListener? { get set }

    /// Tells the producer to start producing events.
    func startProducingEvents()

    /// Tells the producer to stop producing events.
    func stopProducingEvents()
}
