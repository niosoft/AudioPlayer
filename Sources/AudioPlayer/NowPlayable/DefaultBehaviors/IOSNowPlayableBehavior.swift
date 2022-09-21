//
//  IOSNowPlayableBehavior.swift
//  AudioPlayer
//
//  Created by Dionisis Karatzas on 20/9/22.
//  Copyright © 2022 Niosoft. All rights reserved.
//

#if os(iOS)
import Foundation
import MediaPlayer

public class IOSNowPlayableBehavior: NowPlayable {
	private weak var audioPlayer: AudioPlayer?
    
	public var defaultAllowsExternalPlayback: Bool { return true }
    
	public var defaultRegisteredCommands: [NowPlayableCommand] { [
                .play,
                .pause,
                .skipBackward,
                .skipForward,
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
    
	public func handleNowPlayableSessionStart() throws {
        
//        let audioSession = AVAudioSession.sharedInstance()
//
//        try audioSession.setCategory(.playback, mode: .default)
//
//         // Make the audio session active.
//
//         try audioSession.setActive(true)
    }
    
	public func handleNowPlayableSessionEnd() {
        
        // Make the audio session inactive.
        
//        do {
//            try AVAudioSession.sharedInstance().setActive(false)
//        } catch {
//            print("Failed to deactivate audio session, error: \(error)")
//        }
    }
    
	public func handleNowPlayableItemChange(metadata: NowPlayableStaticMetadata) {
        
        // Use the default behavior for setting player item metadata.
        
        setNowPlayingMetadata(metadata)
    }
    
	public func handleNowPlayablePlaybackChange(playing: Bool) { }

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
