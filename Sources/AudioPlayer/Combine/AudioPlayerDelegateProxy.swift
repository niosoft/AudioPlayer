//
//  AudioPlayerDelegateProxy.swift
//  AudioPlayer
//
//  Created by Dionisis Karatzas on 11/10/22.
//  Copyright © 2022 Niosoft. All rights reserved.
//

import Combine
import Foundation

public final class AudioPlayerDelegateProxy: AudioPlayerDelegate {
    public var publisher: AnyPublisher<Action, Never> {
        subject.eraseToAnyPublisher()
    }

    private let subject = PassthroughSubject<Action, Never>()

    public init(_ player: AudioPlayer) {
        player.delegate = self
    }

    public func audioPlayer(_ audioPlayer: AudioPlayer, didChangeStateFrom from: AudioPlayerState, to state: AudioPlayerState) {
        subject.send(.didChangeState(from: from, to: state))
    }

    public func audioPlayer(_ audioPlayer: AudioPlayer, willStartPlaying item: AudioItem) {
        subject.send(.willStartPlaying(item))
    }

    public func audioPlayer(_ audioPlayer: AudioPlayer, didUpdateProgressionTo time: TimeInterval, percentageRead: Float) {
        subject.send(.didUpdateProgression(to: time, percentageRead: percentageRead))
    }

    public func audioPlayer(_ audioPlayer: AudioPlayer, didFindDuration duration: TimeInterval, for item: AudioItem) {
        subject.send(.didFindDuration(duration, for: item))
    }

    public func audioPlayer(_ audioPlayer: AudioPlayer, didUpdateEmptyMetadataOn item: AudioItem, withData data: Metadata) {
        subject.send(.didUpdateEmptyMetadata(on: item, withData: data))
    }

    public func audioPlayer(_ audioPlayer: AudioPlayer, didLoad range: TimeRange, for item: AudioItem) {
        subject.send(.didLoad(range, for: item))
    }
}

public extension AudioPlayerDelegateProxy {
    enum Action {
        case didChangeState(from: AudioPlayerState, to: AudioPlayerState)
        case willStartPlaying(AudioItem)
        case didUpdateProgression(to: TimeInterval, percentageRead: Float)
        case didFindDuration(TimeInterval, for: AudioItem)
        case didUpdateEmptyMetadata(on: AudioItem, withData: Metadata)
        case didLoad(TimeRange, for: AudioItem)
    }
}
