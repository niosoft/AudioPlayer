//
//  AudioPlayer+NetworkEvent.swift
//  AudioPlayer
//
//  Created by Dionisis Karatzas on 20/9/22.
//  Copyright © 2022 Niosoft. All rights reserved.
//

extension AudioPlayer {
    /// Handles network events.
    ///
    /// - Parameters:
    ///   - producer: The event producer that generated the network event.
    ///   - event: The network event.
    func handleNetworkEvent(from _: EventProducer, with event: NetworkEventProducer.NetworkEvent) {
        switch event {
        case .connectionLost:
            // Early exit if state prevents us to handle connection loss
            guard let currentItem = currentItem, !state.isWaitingForConnection else {
                return
            }

            // In case we're not playing offline file
            if !(currentItem.soundURLs[currentQuality]?.ap_isOfflineURL ?? false) {
                stateWhenConnectionLost = state

                if let currentItem = player?.currentItem, currentItem.isPlaybackBufferEmpty {
                    if case .playing = state {
                        qualityAdjustmentEventProducer.interruptionCount += 1
                    }

                    state = .waitingForConnection
                    backgroundHandler.beginBackgroundTask()
                }
            }

        case .connectionRetrieved:
            // Early exit if connection wasn't lost during playing or `resumeAfterConnectionLoss`
            // isn't enabled.
            guard let lossDate = networkEventProducer.connectionLossDate,
                  let stateWhenLost = stateWhenConnectionLost, resumeAfterConnectionLoss
            else {
                return
            }

            let isAllowedToRestart = lossDate.timeIntervalSinceNow < maximumConnectionLossTime
            let wasPlayingBeforeLoss = !stateWhenLost.isStopped

            if isAllowedToRestart, wasPlayingBeforeLoss {
                retryOrPlayNext()
            }

            stateWhenConnectionLost = nil

        case .networkChanged:
            break
        }
    }
}
