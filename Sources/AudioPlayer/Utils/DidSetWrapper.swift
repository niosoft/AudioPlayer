//
//  DidSetWrapper.swift
//  AudioPlayer
//
//  Created by Dionisis Karatzas on 20/9/22.
//  Copyright © 2022 Niosoft. All rights reserved.
//

import Combine
import Foundation

@propertyWrapper
public class DidSet<Value> {
    private var val: Value
    private let subject: CurrentValueSubject<Value, Never>

    public init(wrappedValue value: Value) {
        val = value
        subject = CurrentValueSubject(value)
        wrappedValue = value
    }

    public var wrappedValue: Value {
        set {
            val = newValue
            subject.send(val)
        }
        get { val }
    }

    public var projectedValue: CurrentValueSubject<Value, Never> { subject }
}
