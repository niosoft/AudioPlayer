//
//  MacNowPlayableBehavior.swift
//  AudioPlayer
//
//  Created by Dionisis Karatzas on 20/9/22.
//  Copyright © 2022 Niosoft. All rights reserved.
//

#if os(macOS)
import Foundation
import MediaPlayer

public class MacNowPlayableBehavior: NowPlayable {
	private weak var audioPlayer: AudioPlayer?

	public var defaultAllowsExternalPlayback: Bool { return true }

	public var defaultRegisteredCommands: [NowPlayableCommand] {
		return [.play,
				.pause,
		]
	}

	public var defaultDisabledCommands: [NowPlayableCommand] {

		// By default, no commands are disabled.

		return []
	}

	public init() { }

	public func handleNowPlayableConfiguration(audioPlayer: AudioPlayer) throws {
		self.audioPlayer = audioPlayer

		// Use the default behavior for registering commands.

		try configureRemoteCommands(defaultRegisteredCommands, disabledCommands: defaultDisabledCommands, commandHandler: handleCommand)
	}

	public func handleNowPlayableSessionStart() {

		// Set the playback state.

		MPNowPlayingInfoCenter.default().playbackState = .paused
	}

	public func handleNowPlayableSessionEnd() {

		// Set the playback state.

		MPNowPlayingInfoCenter.default().playbackState = .stopped
	}

	public func handleNowPlayableItemChange(metadata: NowPlayableStaticMetadata) {

		// Use the default behavior for setting player item metadata.

		setNowPlayingMetadata(metadata)
	}

	public func handleNowPlayablePlaybackChange(playing isPlaying: Bool) {

		// Set the playback state.

		MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
	}

	private func handleCommand(command: NowPlayableCommand, event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
		switch command {
			case .pause:
				audioPlayer?.pause()

			case .play:
				audioPlayer?.resume()

			case .stop:
				audioPlayer?.stop()

			case .changePlaybackRate:
				guard let event = event as? MPChangePlaybackRateCommandEvent else { return .commandFailed }
				audioPlayer?.rate = event.playbackRate

			case .changePlaybackPosition:
				guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
				audioPlayer?.seek(to: event.positionTime)

			default:
				break
		}

		return .success
	}
}
#endif
