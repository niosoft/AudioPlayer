//
//  Publisher+didSet.swift
//  AudioPlayer
//
//  Created by Dionisis Karatzas on 20/9/22.
//  Copyright © 2022 Niosoft. All rights reserved.
//

import Foundation
import Combine

extension Published.Publisher {
    
    /**
     Add @Published projected value didSet Publisher.
     ```
     self.viewModel.$items.didSet.sink { [weak self] (models) in
        self?.updateData()
     }.store(in: &self.subscriptions)
     ```
     */
    var didSet: AnyPublisher<Value, Never> {
        self.receive(on: RunLoop.main).eraseToAnyPublisher()
    }
}
