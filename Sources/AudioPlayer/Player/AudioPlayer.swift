//
//  AudioPlayer.swift
//  AudioPlayer
//
//  Created by Dionisis Karatzas on 20/9/22.
//  Copyright © 2022 Niosoft. All rights reserved.
//

import AVFoundation
import MediaPlayer

/// An `AudioPlayer` instance is used to play `AudioPlayerItem`. It's an easy to use AVPlayer with simple methods to
/// handle the whole playing audio process.
///
/// You can get events (such as state change or time observation) by registering a delegate.
public class AudioPlayer {
    // MARK: Handlers

    /// The background handler.
    let backgroundHandler = BackgroundHandler()

    // MARK: Event producers

    /// The network event producer.
    let networkEventProducer = NetworkEventProducer()

    /// The player event producer.
    let playerEventProducer = PlayerEventProducer()

    /// The seek event producer.
    let seekEventProducer = SeekEventProducer()

    /// The NowPlayable service.
	var nowPlayableService: NowPlayableService?

    /// The quality adjustment event producer.
    var qualityAdjustmentEventProducer = QualityAdjustmentEventProducer()

    /// The audio item event producer.
    var audioItemEventProducer = AudioItemEventProducer()

    /// The retry event producer.
    var retryEventProducer = RetryEventProducer()

    // MARK: Player

    /// The queue containing items to play.
    var queue: AudioItemQueue?

    /// The audio player.
    var player: AVPlayer? {
        didSet {
            if #available(OSX 10.11, *) {
                player?.allowsExternalPlayback = false
            }
            player?.volume = volume
            player?.rate = rate
            updatePlayerForBufferingStrategy()

            if let player = player {
                playerEventProducer.player = player
                audioItemEventProducer.item = currentItem
                playerEventProducer.startProducingEvents()
                networkEventProducer.startProducingEvents()
                audioItemEventProducer.startProducingEvents()
                qualityAdjustmentEventProducer.startProducingEvents()
            } else {
                playerEventProducer.player = nil
                audioItemEventProducer.item = nil
                playerEventProducer.stopProducingEvents()
                networkEventProducer.stopProducingEvents()
                audioItemEventProducer.stopProducingEvents()
                qualityAdjustmentEventProducer.stopProducingEvents()
            }
        }
    }

	public var avPlayer: AVPlayer? {
		return player
	}

    /// The current item being played.
    public var currentItem: AudioItem? {
        didSet {
            if let currentItem = currentItem {
                // Stops the current player
                player?.rate = 0
                player = nil

                // Ensures the audio session got started
                setAudioSession(active: true)

                // Sets new state
                let info = currentItem.url(for: currentQuality)
                if networkEventProducer.status.isReachable || info.url.ap_isOfflineURL {
                    state = .buffering
                    backgroundHandler.beginBackgroundTask()
                } else {
                    stateWhenConnectionLost = .buffering
                    state = .waitingForConnection
                    backgroundHandler.beginBackgroundTask()
                    return
                }
                
                // Reset special state flags
                pausedForInterruption = false

                // Create new AVPlayerItem
                let playerItem = AVPlayerItem(url: info.url)

                if #available(iOS 10.0, tvOS 10.0, OSX 10.12, *) {
                    playerItem.preferredForwardBufferDuration = self.preferredForwardBufferDuration
                }

                // Creates new player
                player = AVPlayer(playerItem: playerItem)

                currentQuality = info.quality

                // Calls delegate
                if oldValue != currentItem {
                    delegate?.audioPlayer(self, willStartPlaying: currentItem)
                }
                player?.rate = rate
            } else {
                stop()
            }
        }
    }

    // MARK: Public properties

    /// The delegate that will be called upon events.
    public weak var delegate: AudioPlayerDelegate?

    /// Defines the maximum to wait after a connection loss before putting the player to Stopped mode and cancelling
    /// the resume. Default value is 60 seconds.
    public var maximumConnectionLossTime = TimeInterval(60)

    /// Defines whether the player should automatically adjust sound quality based on the number of interruption before
    /// a delay and the maximum number of interruption whithin this delay. Default value is `true`.
    public var adjustQualityAutomatically = true

    /// Defines the default quality used to play. Default value is `.medium`
    public var defaultQuality = AudioQuality.medium

    /// Defines the delay within which the player wait for an interruption before upgrading the quality. Default value
    /// is 10 minutes.
    public var adjustQualityTimeInternal: TimeInterval {
        get {
            return qualityAdjustmentEventProducer.adjustQualityTimeInternal
        }
        set {
            qualityAdjustmentEventProducer.adjustQualityTimeInternal = newValue
        }
    }

    /// Defines the maximum number of interruption to have within the `adjustQualityTimeInterval` delay before
    /// downgrading the quality. Default value is 5.
    public var adjustQualityAfterInterruptionCount: Int {
        get {
            return qualityAdjustmentEventProducer.adjustQualityAfterInterruptionCount
        }
        set {
            qualityAdjustmentEventProducer.adjustQualityAfterInterruptionCount = newValue
        }
    }

    /// The maximum number of interruption before putting the player to Stopped mode. Default value is 10.
    public var maximumRetryCount: Int {
        get {
            return retryEventProducer.maximumRetryCount
        }
        set {
            retryEventProducer.maximumRetryCount = newValue
        }
    }

    /// The delay to wait before cancelling last retry and retrying. Default value is 10 seconds.
    public var retryTimeout: TimeInterval {
        get {
            return retryEventProducer.retryTimeout
        }
        set {
            retryEventProducer.retryTimeout = newValue
        }
    }

    /// Defines whether the player should resume after a system interruption or not. Default value is `true`.
    public var resumeAfterInterruption = true

    /// Defines whether the player should resume after a connection loss or not. Default value is `true`.
    public var resumeAfterConnectionLoss = true

    /// Defines whether the player should set the now playing metadata or not. Default value is `true`.
    public var setNowPlayingMetadata = true

    /// Defines the mode of the player. Default is `.Normal`.
    public var mode = AudioPlayerMode.normal {
        didSet {
            queue?.mode = mode
        }
    }

    /// Defines the volume of the player. `1.0` means 100% and `0.0` is 0%.
    public var volume = Float(1) {
        didSet {
            player?.volume = volume
        }
    }

    /// Defines the rate of the player. Default value is 1.
    public var rate = Float(1) {
        didSet {
            if case .playing = state {
                player?.rate = rate
                if let metadata = currentItemDynamicMetadata() {
                    nowPlayableService?.handleNowPlayablePlaybackChange(isPlaying: state == .playing, metadata: metadata)
                } else {
                    nowPlayableService?.handleNowPlayablePlaybackChange(isPlaying: state == .playing)
                }
            }
        }
    }
    
    /// Defines the buffering strategy used to determine how much to buffer before starting playback
    public var bufferingStrategy: AudioPlayerBufferingStrategy = .defaultBuffering {
        didSet {
            updatePlayerForBufferingStrategy()
        }
    }
    
    /// Defines the preferred buffer duration in seconds before playback begins. Defaults to 60.
    /// Works on iOS/tvOS 10+ when `bufferingStrategy` is `.playWhenPreferredBufferDurationFull`.
    public var preferredBufferDurationBeforePlayback = TimeInterval(60)
    
    /// Defines the preferred size of the forward buffer for the underlying `AVPlayerItem`.
    /// Works on iOS/tvOS 10+, default is 0, which lets `AVPlayer` decide.
    public var preferredForwardBufferDuration = TimeInterval(0)

    /// Defines how to behave when the user is seeking through the lockscreen or the control center.
    ///
    /// - multiplyRate: Multiples the rate by a factor.
    /// - changeTime:   Changes the current position by adding/substracting a time interval.
    public enum SeekingBehavior {
        case multiplyRate(Float)
        case changeTime(every: TimeInterval, delta: TimeInterval)

        func handleSeekingStart(player: AudioPlayer, forward: Bool) {
            switch self {
            case .multiplyRate(let rateMultiplier):
                if forward {
                    player.rate *= rateMultiplier
                } else {
                    player.rate = -(player.rate * rateMultiplier)
                }

            case .changeTime:
                player.seekEventProducer.isBackward = !forward
                player.seekEventProducer.startProducingEvents()
            }
        }

        func handleSeekingEnd(player: AudioPlayer, forward: Bool) {
            switch self {
            case .multiplyRate(let rateMultiplier):
                if forward {
                    player.rate /= rateMultiplier
                } else {
                    player.rate = -(player.rate / rateMultiplier)
                }

            case .changeTime:
                player.seekEventProducer.stopProducingEvents()
            }
        }
    }

    /// Defines the rate behavior of the player when the backward/forward buttons are pressed. Default value
    /// is `multiplyRate(2)`.
    public var seekingBehavior = SeekingBehavior.multiplyRate(2) {
        didSet {
            if case .changeTime(let timerInterval, _) = seekingBehavior {
                seekEventProducer.intervalBetweenEvents = timerInterval
            }
        }
    }

    // MARK: Readonly properties

    /// The current state of the player.
    public internal(set) var state = AudioPlayerState.stopped {
        didSet {

            if state != oldValue {
                if case .buffering = state {
                    backgroundHandler.beginBackgroundTask()
                } else if case .buffering = oldValue {
                    backgroundHandler.endBackgroundTask()
                }

                if let metadata = currentItemDynamicMetadata() {
                    nowPlayableService?.handleNowPlayablePlaybackChange(isPlaying: state == .playing, metadata: metadata)
                } else {
                    nowPlayableService?.handleNowPlayablePlaybackChange(isPlaying: state == .playing)
                }

                delegate?.audioPlayer(self, didChangeStateFrom: oldValue, to: state)
            }
        }
    }

    /// The current quality being played.
    public internal(set) var currentQuality: AudioQuality

    // MARK: Private properties

    /// A boolean value indicating whether the player has been paused because of a system interruption.
    var pausedForInterruption = false

    /// A boolean value indicating if quality is being changed. It's necessary for the interruption count to not be
    /// incremented while new quality is buffering.
    var qualityIsBeingChanged = false

    /// The state before the player went into .Buffering. It helps to know whether to restart or not the player.
    var stateBeforeBuffering: AudioPlayerState?

    /// The state of the player when the connection was lost
    var stateWhenConnectionLost: AudioPlayerState?

    // MARK: Initialization

    /// Initializes a new AudioPlayer.
    public init() {
        currentQuality = defaultQuality

        playerEventProducer.eventListener = self
        networkEventProducer.eventListener = self
        audioItemEventProducer.eventListener = self
        qualityAdjustmentEventProducer.eventListener = self
    }

	public convenience init(nowPlayableService: NowPlayableService) {
		self.init()
		self.nowPlayableService = nowPlayableService
        try? nowPlayableService.handleNowPlayableConfiguration(commandHandler: handleCommand(command:event:))
	}

    private func handleCommand(command: NowPlayableCommand, event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        switch command {
        case .pause:
            pause()

        case .play:
            resume()
        default:
           return .success
        }

        return .success

    }

    /// Deinitializes the AudioPlayer. On deinit, the player will simply stop playing anything it was previously
    /// playing.
    deinit {
        stop()
    }

    // MARK: Utility methods

    /// Enables or disables the `AVAudioSession` and sets the right category.
    ///
    /// - Parameter active: A boolean value indicating whether the audio session should be set to active or not.
    func setAudioSession(active: Bool) {
		DispatchQueue.global().async {[weak self] in
			#if os(iOS) || os(tvOS)
				_ = try? AVAudioSession.sharedInstance().setCategory(.playback)
				_ = try? AVAudioSession.sharedInstance().setActive(active)
			#endif

			if active {
				try? self?.nowPlayableService?.handleNowPlayableSessionStart()
			} else {
				self?.nowPlayableService?.handleNowPlayableSessionEnd()
			}
		}
    }

    // MARK: Public computed properties

    /// Boolean value indicating whether the player should resume playing (after buffering)
    var shouldResumePlaying: Bool {
        return !state.isPaused &&
            (stateWhenConnectionLost.map { !$0.isPaused } ?? true) &&
            (stateBeforeBuffering.map { !$0.isPaused } ?? true)
    }

    // MARK: Retrying

    /// This will retry to play current item and seek back at the correct position if possible (or enabled). If not,
    /// it'll just play the next item in queue.
    func retryOrPlayNext() {
        guard !state.isPlaying else {
            retryEventProducer.stopProducingEvents()
            return
        }

        let cip = currentItemProgression
        let ci = currentItem
        currentItem = ci
        if let cip = cip {
            // We can't call self.seek(to:) in here since the player is new
            // and `cip` is probably not in the seekableTimeRanges.
            player?.seek(to: CMTime(timeInterval: cip))
        }
    }
    
    /// Updates the current player based on the current buffering strategy.
    /// Only has an effect on iOS 10+, tvOS 10+ and macOS 10.12+
    func updatePlayerForBufferingStrategy() {
        if #available(iOS 10.0, tvOS 10.0, OSX 10.12, *) {
            player?.automaticallyWaitsToMinimizeStalling = self.bufferingStrategy != .playWhenBufferNotEmpty
        }
    }
    
    /// Updates a given player item based on the `preferredForwardBufferDuration` set.
    /// Only has an effect on iOS 10+, tvOS 10+ and macOS 10.12+
    func updatePlayerItemForBufferingStrategy(_ playerItem: AVPlayerItem) {
        // Nothing strategy-specific yet
        if #available(iOS 10.0, tvOS 10.0, OSX 10.12, *) {
            playerItem.preferredForwardBufferDuration = self.preferredForwardBufferDuration
        }
    }
}

extension AudioPlayer: EventListener {
    /// The implementation of `EventListener`. It handles network events, player events, audio item events, quality
    /// adjustment events, retry events and seek events.
    ///
    /// - Parameters:
    ///   - event: The event.
    ///   - eventProducer: The producer of the event.
    func onEvent(_ event: Event, generetedBy eventProducer: EventProducer) {
        if let event = event as? NetworkEventProducer.NetworkEvent {
            handleNetworkEvent(from: eventProducer, with: event)
        } else if let event = event as? PlayerEventProducer.PlayerEvent {
            handlePlayerEvent(from: eventProducer, with: event)
        } else if let event = event as? AudioItemEventProducer.AudioItemEvent {
            handleAudioItemEvent(from: eventProducer, with: event)
        } else if let event = event as? QualityAdjustmentEventProducer.QualityAdjustmentEvent {
            handleQualityEvent(from: eventProducer, with: event)
        } else if let event = event as? RetryEventProducer.RetryEvent {
            handleRetryEvent(from: eventProducer, with: event)
        } else if let event = event as? SeekEventProducer.SeekEvent {
            handleSeekEvent(from: eventProducer, with: event)
        }
    }

    func currentItemDynamicMetadata() -> NowPlayableDynamicMetadata? {
        if let player, let currentItemDuration, let currentItemProgression {
            return NowPlayableDynamicMetadata(rate: player.rate,
                                              position: Float(currentItemProgression),
                                              duration: Float(currentItemDuration),
                                              currentLanguageOptions: [.init()], availableLanguageOptionGroups: [.init()])
        }
        return nil
    }
}
