//
//  AudioItem.swift
//  AudioPlayer
//
//  Created by Dionisis Karatzas on 20/9/22.
//  Copyright © 2022 Niosoft. All rights reserved.
//

import AVFoundation
import MediaPlayer
#if os(iOS) || os(tvOS)
    import UIKit

    public typealias Image = UIImage
#else
    import Cocoa

    public typealias Image = NSImage
#endif

// MARK: - AudioQuality

/// `AudioQuality` differentiates qualities for audio.
///
/// - low: The lowest quality.
/// - medium: The quality between highest and lowest.
/// - high: The highest quality.
public enum AudioQuality: Int {
    case low = 0
    case medium = 1
    case high = 2
}

// MARK: - AudioItemURL

/// `AudioItemURL` contains information about an Item URL such as its quality.
public struct AudioItemURL {
    /// The quality of the stream.
    public let quality: AudioQuality

    /// The url of the stream.
    public let url: URL

    /// Initializes an AudioItemURL.
    ///
    /// - Parameters:
    ///   - quality: The quality of the stream.
    ///   - url: The url of the stream.
    public init?(quality: AudioQuality, url: URL?) {
        guard let url = url else { return nil }

        self.quality = quality
        self.url = url
    }
}

// MARK: - AudioItem

/// An `AudioItem` instance contains every piece of information needed for an `AudioPlayer` to play.
///
/// URLs can be remote or local.
public class AudioItem: ObservableObject, Equatable {
    private let id = UUID()
    public static func == (lhs: AudioItem, rhs: AudioItem) -> Bool {
        return lhs.id == rhs.id
    }

    /// Returns the available qualities.
    public let soundURLs: [AudioQuality: URL]

    // MARK: Initialization

    /// Initializes an AudioItem. Fails if every urls are nil.
    ///
    /// - Parameters:
    ///   - highQualitySoundURL: The URL for the high quality sound.
    ///   - mediumQualitySoundURL: The URL for the medium quality sound.
    ///   - lowQualitySoundURL: The URL for the low quality sound.
    public convenience init?(highQualitySoundURL: URL? = nil,
                             mediumQualitySoundURL: URL? = nil,
                             lowQualitySoundURL: URL? = nil)
    {
        var URLs = [AudioQuality: URL]()
        if let highURL = highQualitySoundURL {
            URLs[.high] = highURL
        }
        if let mediumURL = mediumQualitySoundURL {
            URLs[.medium] = mediumURL
        }
        if let lowURL = lowQualitySoundURL {
            URLs[.low] = lowURL
        }
        self.init(soundURLs: URLs)
    }

    /// Initializes an `AudioItem`.
    ///
    /// - Parameter soundURLs: The URLs of the sound associated with its quality wrapped in a `Dictionary`.
    public init?(soundURLs: [AudioQuality: URL]) {
        self.soundURLs = soundURLs

        if soundURLs.isEmpty {
            return nil
        }
    }

    // MARK: Quality selection

    /// Returns the highest quality URL found or nil if no URLs are available
    public var highestQualityURL: AudioItemURL {
        // swiftlint:disable force_unwrapping
        return (AudioItemURL(quality: .high, url: soundURLs[.high]) ??
            AudioItemURL(quality: .medium, url: soundURLs[.medium]) ??
            AudioItemURL(quality: .low, url: soundURLs[.low]))!
    }

    /// Returns the medium quality URL found or nil if no URLs are available
    public var mediumQualityURL: AudioItemURL {
        // swiftlint:disable force_unwrapping
        return (AudioItemURL(quality: .medium, url: soundURLs[.medium]) ??
            AudioItemURL(quality: .low, url: soundURLs[.low]) ??
            AudioItemURL(quality: .high, url: soundURLs[.high]))!
    }

    /// Returns the lowest quality URL found or nil if no URLs are available
    public var lowestQualityURL: AudioItemURL {
        // swiftlint:disable force_unwrapping
        return (AudioItemURL(quality: .low, url: soundURLs[.low]) ??
            AudioItemURL(quality: .medium, url: soundURLs[.medium]) ??
            AudioItemURL(quality: .high, url: soundURLs[.high]))!
    }

    /// Returns an URL that best fits a given quality.
    ///
    /// - Parameter quality: The quality for the requested URL.
    /// - Returns: The URL that best fits the given quality.
    func url(for quality: AudioQuality) -> AudioItemURL {
        switch quality {
        case .high:
            return highestQualityURL
        case .medium:
            return mediumQualityURL
        default:
            return lowestQualityURL
        }
    }

    // MARK: Additional properties

    /// The artist of the item.
    ///
    /// This can change over time which is why the property is @Published.
    @DidSet public private(set) var artist: String?

    /// The title of the item.
    ///
    /// This can change over time which is why the property is @Published.
    @DidSet public private(set) var title: String?

    /// The album of the item.
    ///
    /// This can change over time which is why the property is @Published.
    @DidSet public private(set) var album: String?

    /// The track count of the item's album.
    ///
    /// This can change over time which is why the property is @Published.
    @DidSet public private(set) var trackCount: NSNumber?

    /// The track number of the item in its album.
    ///
    /// This can change over time which is why the property is @Published.
    @DidSet public private(set) var trackNumber: NSNumber?

    /// The artwork image of the item.
    public private(set) var artworkImage: Image? {
        get {
            return artwork?.image(at: imageSize ?? CGSize(width: 512, height: 512))
        }
        set {
            imageSize = newValue?.size
            artwork = newValue.map { image in
                MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            }
        }
    }

    /// The artwork image of the item.
    ///
    /// This can change over time which is why the property is @Published.
    @DidSet public private(set) var artwork: MPMediaItemArtwork?

    /// The image size.
    private var imageSize: CGSize?

    // MARK: Metadata

    /// Parses the metadata coming from the stream/file specified in the URL's. The default behavior is to set values
    /// for every property that is nil. Customization is available through subclassing.
    ///
    /// - Parameter items: The metadata items.
    public func parseMetadata(_ items: [AVMetadataItem]) {
        items.forEach {
            if let commonKey = $0.commonKey {
                switch commonKey {
                case AVMetadataKey.commonKeyTitle where title == nil:
                    title = $0.value as? String
                case AVMetadataKey.commonKeyArtist where artist == nil:
                    artist = $0.value as? String
                case AVMetadataKey.commonKeyAlbumName where album == nil:
                    album = $0.value as? String
                case AVMetadataKey.id3MetadataKeyTrackNumber where trackNumber == nil:
                    trackNumber = $0.value as? NSNumber
                case AVMetadataKey.commonKeyArtwork where artwork == nil:
                    artworkImage = ($0.value as? Data).flatMap { Image(data: $0) }
                default:
                    break
                }
            }
        }
    }
}
