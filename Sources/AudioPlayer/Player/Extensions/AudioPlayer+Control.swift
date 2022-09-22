//
//  AudioPlayer+Control.swift
//  AudioPlayer
//
//  Created by Dionisis Karatzas on 20/9/22.
//  Copyright © 2022 Niosoft. All rights reserved.
//

import AVFoundation
import MediaPlayer
#if os(iOS) || os(tvOS)
import UIKit
#endif

extension AudioPlayer {
    /// Resumes the player.
    public func resume() {
        // Ensure pause flag is no longer set
        pausedForInterruption = false

        player?.rate = rate

        // We don't wan't to change the state to Playing in case it's Buffering. That
        // would be a lie.
        if !state.isPlaying && !state.isBuffering {
            state = .playing
        }

        retryEventProducer.startProducingEvents()
    }

    /// Pauses the player.
    public func pause() {
        // We ensure the player actually pauses
        player?.rate = 0
        state = .paused

        retryEventProducer.stopProducingEvents()

        // Let's begin a background task for the player to keep buffering if the app is in
        // background. This will mimic the default behavior of `AVPlayer` when pausing while the
        // app is in foreground.
        backgroundHandler.beginBackgroundTask()
    }

    /// Starts playing the current item immediately. Works on iOS/tvOS 10+ and macOS 10.12+
    func playImmediately() {
        if #available(iOS 10.0, tvOS 10.0, OSX 10.12, *) {
            self.state = .playing
            player?.playImmediately(atRate: rate)

            retryEventProducer.stopProducingEvents()
            backgroundHandler.endBackgroundTask()
        }
    }

    /// Plays previous item in the queue or rewind current item.
    public func previous() {
        if let previousItem = queue?.previousItem() {
            currentItem = previousItem
        } else {
            seek(to: 0)
        }
    }

    /// Plays next item in the queue.
    public func next() {
        if let nextItem = queue?.nextItem() {
            currentItem = nextItem
        }
    }

    /// Plays the next item in the queue and if there isn't, the player will stop.
    public func nextOrStop() {
        if let nextItem = queue?.nextItem() {
            currentItem = nextItem
        } else {
            stop()
        }
    }

    /// Stops the player and clear the queue.
    public func stop() {
        retryEventProducer.stopProducingEvents()

        if let _ = player {
            player?.rate = 0
            player = nil
        }
        if let _ = currentItem {
            currentItem = nil
        }
        if let _ = queue {
            queue = nil
        }

        setAudioSession(active: false)
        state = .stopped
    }

    /// Seeks to a specific time.
    ///
    /// - Parameters:
    ///   - time: The time to seek to.
    ///   - byAdaptingTimeToFitSeekableRanges: A boolean value indicating whether the time should be adapted to current
    ///         seekable ranges in order to be bufferless.
    ///   - toleranceBefore: The tolerance allowed before time.
    ///   - toleranceAfter: The tolerance allowed after time.
    ///   - completionHandler: The optional callback that gets executed upon completion with a boolean param indicating
    ///         if the operation has finished.
    public func seek(to time: TimeInterval,
                     byAdaptingTimeToFitSeekableRanges: Bool = false,
                     toleranceBefore: CMTime = CMTime.positiveInfinity,
                     toleranceAfter: CMTime = CMTime.positiveInfinity,
                     completionHandler: ((Bool) -> Void)? = nil) {
        guard let earliest = currentItemSeekableRange?.earliest,
              let latest = currentItemSeekableRange?.latest else {
            // In case we don't have a valid `seekableRange`, although this *shouldn't* happen
            // let's just call `AVPlayer.seek(to:)` with given values.
            seekSafely(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter,
                       completionHandler: completionHandler)
            return
        }

        if !byAdaptingTimeToFitSeekableRanges || (time >= earliest && time <= latest) {
            // Time is in seekable range, there's no problem here.
            seekSafely(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter,
                       completionHandler: completionHandler)
        } else if time < earliest {
            // Time is before seekable start, so just move to the most early position as possible.
            seekToSeekableRangeStart(padding: 1, completionHandler: completionHandler)
        } else if time > latest {
            // Time is larger than possibly, so just move forward as far as possible.
            seekToSeekableRangeEnd(padding: 1, completionHandler: completionHandler)
        }
    }

    public func togglePlayPause() {
        switch state {
        case .stopped:
            resume()

        case .playing:
            pause()

        case .paused:
            resume()
        default:
            break
        }
    }

    /// Seeks backwards as far as possible.
    ///
    /// - Parameter padding: The padding to apply if any.
    /// - completionHandler: The optional callback that gets executed upon completion with a boolean param indicating
    ///     if the operation has finished.
    public func seekToSeekableRangeStart(padding: TimeInterval, completionHandler: ((Bool) -> Void)? = nil) {
        guard let range = currentItemSeekableRange else {
            completionHandler?(false)
            return
        }
        let position = min(range.latest, range.earliest + padding)
        seekSafely(to: position, completionHandler: completionHandler)
    }

    /// Seeks forward as far as possible.
    ///
    /// - Parameter padding: The padding to apply if any.
    /// - completionHandler: The optional callback that gets executed upon completion with a boolean param indicating
    ///     if the operation has finished.
    public func seekToSeekableRangeEnd(padding: TimeInterval, completionHandler: ((Bool) -> Void)? = nil) {
        guard let range = currentItemSeekableRange else {
            completionHandler?(false)
            return
        }
        let position = max(range.earliest, range.latest - padding)
        seekSafely(to: position, completionHandler: completionHandler)
    }

    func handleCommand(command: NowPlayableCommand, event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        switch command {
        case .pause:
            if state == .playing {
                pause()
            }
        case .play:
            if state == .paused {
                resume()
            }
        case .stop:
            stop()
        case .togglePausePlay:
            togglePlayPause()
        case .nextTrack:
            next()
        case .previousTrack:
            previous()
        case .changeRepeatMode:
            guard let event = event as? MPChangeRepeatModeCommandEvent else { return .commandFailed }
            switch event.repeatType {
            case .off:
                mode = .normal
            case .one:
                mode = .repeat
            case .all:
                mode = .repeatAll
            @unknown default:
                break
            }
        case .changePlaybackRate:
            guard let event = event as? MPChangePlaybackRateCommandEvent else { return .commandFailed }
            rate = event.playbackRate
        case .seekBackward:
            guard let event = event as? MPSeekCommandEvent else { return .commandFailed }
            if event.type == .beginSeeking {
                seekingBehavior.handleSeekingStart(player: self, forward: false)
            } else if event.type == .endSeeking {
                seekingBehavior.handleSeekingEnd(player: self, forward: false)
            }
        case .seekForward:
            guard let event = event as? MPSeekCommandEvent else { return .commandFailed }
            if event.type == .beginSeeking {
                seekingBehavior.handleSeekingStart(player: self, forward: true)
            } else if event.type == .endSeeking {
                seekingBehavior.handleSeekingEnd(player: self, forward: true)
            }
        case .skipBackward:
            MPRemoteCommandCenter.shared().skipBackwardCommand.preferredIntervals = [15.0]
        case .skipForward:
            MPRemoteCommandCenter.shared().skipForwardCommand.preferredIntervals = [15.0]
        }
        return .success
    }
}

extension AudioPlayer {

    fileprivate func seekSafely(to time: TimeInterval,
                                toleranceBefore: CMTime = CMTime.positiveInfinity,
                                toleranceAfter: CMTime = CMTime.positiveInfinity,
                                completionHandler: ((Bool) -> Void)?) {
        guard let completionHandler = completionHandler else {
            player?.seek(to: CMTime(timeInterval: time), toleranceBefore: toleranceBefore,
                         toleranceAfter: toleranceAfter)
            if let metadata = currentItemDynamicMetadata() {
                nowPlayableService?.handleNowPlayablePlaybackChange(isPlaying: state == .playing, metadata: metadata)
            }
            return
        }
        guard player?.currentItem?.status == .readyToPlay else {
            completionHandler(false)
            return
        }
        player?.seek(to: CMTime(timeInterval: time), toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter,
                     completionHandler: { [weak self] finished in
            completionHandler(finished)
            if let metadata = self?.currentItemDynamicMetadata() {
                self?.nowPlayableService?.handleNowPlayablePlaybackChange(isPlaying: self?.state == .playing, metadata: metadata)
            }
        })
    }
}
