//
//  AVPlayerItem+Combine.swift
//  AudioPlayer
//
//  Created by Dionisis Karatzas on 20/9/22.
//  Copyright © 2022 Niosoft. All rights reserved.
//

import AVFoundation
import AVFoundationCombine
import Combine

public extension AVPlayerItem {
    /// Wrapper around a `NSObject.KeyValueObservingPublisher` for the `loadedTimeRanges` property
    func loadedTimeRangesPublisher() -> AnyPublisher<[NSValue], Never> {
        publisher(for: \.loadedTimeRanges).eraseToAnyPublisher()
    }

    /// Wrapper around a `NSObject.KeyValueObservingPublisher` for the `timedMetadata` property
    func timedMetadataPublisher() -> AnyPublisher<[AVMetadataItem]?, Never> {
        publisher(for: \.timedMetadata).eraseToAnyPublisher()
    }
}
