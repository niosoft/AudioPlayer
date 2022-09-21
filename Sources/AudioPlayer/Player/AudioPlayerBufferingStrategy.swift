//
//  AudioPlayerBufferingStrategy.swift
//  AudioPlayer
//
//  Created by Dionisis Karatzas on 20/9/22.
//  Copyright © 2022 Niosoft. All rights reserved.
//

import Foundation

/// Represents the strategy used for buffering of items before playback is started
public enum AudioPlayerBufferingStrategy: Int {
    /// Uses the default AVPlayer buffering strategy, which buffers very aggressively before starting playback.
    /// This often leads to start of playback being delayed more than necessary.
    case defaultBuffering = 0
    
    /// Uses a strategy better at quickly starting playback. Duration to buffer before playback is customizable through
    /// the `preferredBufferDurationBeforePlayback` variable. Requires iOS/tvOS 10+ to have any effect.
    case playWhenPreferredBufferDurationFull = 1
    
    /// Uses a strategy that simply starts playback whenever the AVPlayerItem buffer is non-empty. Requires iOS/tvOS 10+ to have any effect.
    case playWhenBufferNotEmpty = 2
}
