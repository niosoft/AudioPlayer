//
//  NowPlayableMetadata.swift
//  AudioPlayer
//
//  Created by Dionisis Karatzas on 20/9/22.
//  Copyright © 2022 Niosoft. All rights reserved.
//

import Foundation
import MediaPlayer

public struct NowPlayableStaticMetadata {
	public init(assetURL: URL, mediaType: MPNowPlayingInfoMediaType, isLiveStream: Bool, title: String, artist: String?, artwork: MPMediaItemArtwork?, albumArtist: String?, albumTitle: String?) {
		self.assetURL = assetURL
		self.mediaType = mediaType
		self.isLiveStream = isLiveStream
		self.title = title
		self.artist = artist
		self.artwork = artwork
		self.albumArtist = albumArtist
		self.albumTitle = albumTitle
	}
    
    let assetURL: URL                   // MPNowPlayingInfoPropertyAssetURL
    let mediaType: MPNowPlayingInfoMediaType
                                        // MPNowPlayingInfoPropertyMediaType
    let isLiveStream: Bool              // MPNowPlayingInfoPropertyIsLiveStream
    
    let title: String                   // MPMediaItemPropertyTitle
    let artist: String?                 // MPMediaItemPropertyArtist
    let artwork: MPMediaItemArtwork?    // MPMediaItemPropertyArtwork
    
    let albumArtist: String?            // MPMediaItemPropertyAlbumArtist
    let albumTitle: String?             // MPMediaItemPropertyAlbumTitle
    
}

public struct NowPlayableDynamicMetadata {
	public init(rate: Float, position: Float, duration: Float, currentLanguageOptions: [MPNowPlayingInfoLanguageOption], availableLanguageOptionGroups: [MPNowPlayingInfoLanguageOptionGroup]) {
		self.rate = rate
		self.position = position
		self.duration = duration
		self.currentLanguageOptions = currentLanguageOptions
		self.availableLanguageOptionGroups = availableLanguageOptionGroups
	}
    
    let rate: Float                     // MPNowPlayingInfoPropertyPlaybackRate
    let position: Float                 // MPNowPlayingInfoPropertyElapsedPlaybackTime
    let duration: Float                 // MPMediaItemPropertyPlaybackDuration
    
    let currentLanguageOptions: [MPNowPlayingInfoLanguageOption]
                                        // MPNowPlayingInfoPropertyCurrentLanguageOptions
    let availableLanguageOptionGroups: [MPNowPlayingInfoLanguageOptionGroup]
                                        // MPNowPlayingInfoPropertyAvailableLanguageOptions
    
}
