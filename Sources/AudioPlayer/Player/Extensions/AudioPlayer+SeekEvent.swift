//
//  AudioPlayer+SeekEvent.swift
//  AudioPlayer
//
//  Created by Dionisis Karatzas on 20/9/22.
//  Copyright © 2022 Niosoft. All rights reserved.
//

import Foundation

extension AudioPlayer {
    /// Handles seek events.
    ///
    /// - Parameters:
    ///   - producer: The event producer that generated the seek event.
    ///   - event: The seek event.
    func handleSeekEvent(from _: EventProducer, with event: SeekEventProducer.SeekEvent) {
        guard let currentItemProgression = currentItemProgression,
              case let .changeTime(_, delta) = seekingBehavior else { return }

        switch event {
        case .seekBackward:
            seek(to: currentItemProgression - delta)

        case .seekForward:
            seek(to: currentItemProgression + delta)
        }
    }
}
