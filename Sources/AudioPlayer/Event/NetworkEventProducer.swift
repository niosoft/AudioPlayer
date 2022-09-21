//
//  NetworkEventProducer.swift
//  AudioPlayer
//
//  Created by Dionisis Karatzas on 20/9/22.
//  Copyright © 2022 Niosoft. All rights reserved.
//

import Foundation
import SystemConfiguration

/// A `NetworkEventProducer` generates `NetworkEvent`s when there is changes on the network.
final class NetworkEventProducer: EventProducer {
	/// A `NetworkEvent` is an event a network monitor.
	enum NetworkEvent: Event {
		case networkChanged
		case connectionRetrieved
		case connectionLost
	}

	/// The different status for reachability.
	enum Status {
		case reachableViaWiFi
		case reachableViaData
		case unreachable

		var isReachable: Bool {
			return self != .unreachable
		}
	}

	// MARK: Properties

	/// The reachability reference
	private let reachability: Reachability?

	/// A boolean value indicating whether we're currently listening to events on the player.
	private var listening = false

	/// The current reachability status
	var status: Status {
		guard let reachability = reachability else {
			return .unreachable
		}

		switch reachability.connection {
			case .cellular:
				return .reachableViaData
			case .wifi:
				return .reachableViaWiFi
			case .unavailable:
				return .unreachable
		}
	}

	/// The date at which connection was lost.
	private(set) var connectionLossDate: Date?

	/// The last status before
	private var lastStatus: Status

	/// The listener that will be alerted a new event occured.
	var eventListener: EventListener?

	// MARK: Initialization

	init() {
		reachability = try! Reachability()

		lastStatus = .unreachable
		connectionLossDate = nil

		lastStatus = status
		if lastStatus == .unreachable {
			connectionLossDate = Date()
		}

		reachability?.whenReachable = {[weak self] _ in
			self?.updateStatus()
		}
		reachability?.whenUnreachable = {[weak self] _ in
			self?.updateStatus()
		}
	}

	deinit {
		reachability?.stopNotifier()
	}

	// MARK: EventProducer

	func startProducingEvents() {
		guard !listening else { return }

		lastStatus = status
		if let reachability = reachability {
			do {
				try reachability.startNotifier()
			} catch {
				print("Unable to start notifier")
			}
		}
		listening = true
	}

	func stopProducingEvents() {
		guard listening else { return }

		if let reachability = reachability {
			reachability.stopNotifier()
		}
		listening = false
	}

	// MARK: Status updates

	fileprivate func updateStatus() {
		let status = self.status
		guard status != lastStatus else { return }

		switch status {
			case .reachableViaWiFi, .reachableViaData:
				if lastStatus == .unreachable {
					eventListener?.onEvent(NetworkEvent.connectionRetrieved, generetedBy: self)
				} else {
					eventListener?.onEvent(NetworkEvent.networkChanged, generetedBy: self)
				}
			case .unreachable:
				connectionLossDate = Date()
				eventListener?.onEvent(NetworkEvent.connectionLost, generetedBy: self)
		}

		lastStatus = status
	}
}
