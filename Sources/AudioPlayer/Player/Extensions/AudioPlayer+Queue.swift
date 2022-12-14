//
//  AudioPlayer+Queue.swift
//  AudioPlayer
//
//  Created by Dionisis Karatzas on 20/9/22.
//  Copyright © 2022 Niosoft. All rights reserved.
//

public extension AudioPlayer {
    /// The items in the queue if any.
    var items: [AudioItem]? {
        return queue?.queue
    }

    /// The current item index in queue.
    var currentItemIndexInQueue: Int? {
        return currentItem.flatMap { queue?.items.firstIndex(of: $0) }
    }

    /// A boolean value indicating whether there is a next item to play or not.
    var hasNext: Bool {
        return queue?.hasNextItem ?? false
    }

    /// A boolean value indicating whether there is a previous item to play or not.
    var hasPrevious: Bool {
        return queue?.hasPreviousItem ?? false
    }

    /// Plays an item.
    ///
    /// - Parameter item: The item to play.
    func play(item: AudioItem) {
        play(items: [item])
    }

    /// Creates a queue according to the current mode and plays it.
    ///
    /// - Parameters:
    ///   - items: The items to play.
    ///   - index: The index to start the player with.
    func play(items: [AudioItem], startAtIndex index: Int = 0) {
        if !items.isEmpty {
            queue = AudioItemQueue(items: items, mode: mode)
            queue?.delegate = self
            if let realIndex = queue?.queue.firstIndex(of: items[index]) {
                queue?.nextPosition = realIndex
            }
            currentItem = queue?.nextItem()
        } else {
            stop()
            queue = nil
        }
    }

    /// Adds an item at the end of the queue. If queue is empty and player isn't playing, the behaviour will be similar
    /// to `play(item:)`.
    ///
    /// - Parameter item: The item to add.
    func add(item: AudioItem) {
        add(items: [item])
    }

    /// Adds items at the end of the queue. If the queue is empty and player isn't playing, the behaviour will be
    /// similar to `play(items:)`.
    ///
    /// - Parameter items: The items to add.
    func add(items: [AudioItem]) {
        if let queue = queue {
            queue.add(items: items)
        } else {
            play(items: items)
        }
    }

    /// Removes an item at a specific index in the queue.
    ///
    /// - Parameter index: The index of the item to remove.
    func removeItem(at index: Int) {
        queue?.remove(at: index)
    }
}

extension AudioPlayer: AudioItemQueueDelegate {
    /// Returns a boolean value indicating whether an item should be consider playable in the queue.
    ///
    /// - Parameters:
    ///   - queue: The queue.
    ///   - item: The item we ask the information for.
    /// - Returns: A boolean value indicating whether an item should be consider playable in the queue.
    func audioItemQueue(_: AudioItemQueue, shouldConsiderItem item: AudioItem) -> Bool {
        return delegate?.audioPlayer(self, shouldStartPlaying: item) ?? true
    }
}
