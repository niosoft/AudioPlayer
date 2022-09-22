//
//  NowPlayableCommand.swift
//  AudioPlayer
//
//  Created by Dionisis Karatzas on 20/9/22.
//  Copyright © 2022 Niosoft. All rights reserved.
//

import Foundation
import MediaPlayer

/**
 `NowPlayableCommand` identifies remote command center commands.
 */
public enum NowPlayableCommand: CaseIterable {
    case pause, play, stop, togglePausePlay
    case nextTrack, previousTrack, changeRepeatMode
    case changePlaybackRate, seekBackward, seekForward, skipBackward, skipForward

    // The underlying `MPRemoteCommandCenter` command for this `NowPlayable` command.
    var remoteCommand: MPRemoteCommand {
        let remoteCommandCenter = MPRemoteCommandCenter.shared()

        switch self {

        case .pause:
            return remoteCommandCenter.pauseCommand
        case .play:
            return remoteCommandCenter.playCommand
        case .stop:
            return remoteCommandCenter.stopCommand
        case .togglePausePlay:
            return remoteCommandCenter.togglePlayPauseCommand
        case .nextTrack:
            return remoteCommandCenter.nextTrackCommand
        case .previousTrack:
            return remoteCommandCenter.previousTrackCommand
        case .changeRepeatMode:
            return remoteCommandCenter.changeRepeatModeCommand
        case .changePlaybackRate:
            return remoteCommandCenter.changePlaybackRateCommand
        case .seekBackward:
            return remoteCommandCenter.seekBackwardCommand
        case .seekForward:
            return remoteCommandCenter.seekForwardCommand
        case .skipBackward:
            return remoteCommandCenter.skipBackwardCommand
        case .skipForward:
            return remoteCommandCenter.skipForwardCommand
        }
    }

    // Remove all handlers associated with this command.
    func removeHandler() {
        remoteCommand.removeTarget(nil)
    }

    // Install a handler for this command.
    func addHandler(_ handler: @escaping (NowPlayableCommand, MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus) {
        remoteCommand.addTarget { handler(self, $0) }
    }

    // Disable this command.
    func setDisabled(_ isDisabled: Bool) {
        remoteCommand.isEnabled = !isDisabled
    }
}
