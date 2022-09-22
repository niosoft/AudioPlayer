//
//  NowPlayableError.swift
//  AudioPlayer
//
//  Created by Dionisis Karatzas on 20/9/22.
//  Copyright © 2022 Niosoft. All rights reserved.
//

import Foundation

/**
 `NowPlayableError` declares errors specific to the NowPlayable protocol.
 */
public enum NowPlayableError: LocalizedError {
    case noRegisteredCommands
    case cannotSetCategory(Error)
    case cannotActivateSession(Error)
    case cannotReactivateSession(Error)

    public var errorDescription: String? {
        switch self {
        case .noRegisteredCommands:
            return "At least one remote command must be registered."
        case let .cannotSetCategory(error):
            return "The audio session category could not be set:\n\(error)"
        case let .cannotActivateSession(error):
            return "The audio session could not be activated:\n\(error)"
        case let .cannotReactivateSession(error):
            return "The audio session could not be resumed after interruption:\n\(error)"
        }
    }
}
