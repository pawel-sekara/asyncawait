//
// Created by Paweł Sękara on 20.07.2017.
// Copyright (c) 2017 Codewise sp. z o.o. sp. K. All rights reserved.
//

import Foundation

public protocol FutureType {
    associatedtype Value

    var value: Value? { get }
    var error: Error? { get }

    func await() throws -> Value
}

open class Future<T>: FutureType {
    open private(set) var value: T?
    open private(set) var error: Error?

    private let _semaphore = DispatchSemaphore(value: 0)

    init(completion: @escaping (@escaping (T) -> ()) throws -> ()) {
        do {
            try completion { [weak self] (value) in
                self?.value = value
                self?._semaphore.signal()
            }
        } catch {
            self.error = error
            _semaphore.signal()
        }
    }

    open func await() throws -> Value {
        return try await(timeoutInterval: .seconds(60))
    }

    open func await(timeoutInterval: DispatchTimeInterval) throws -> T {
        guard !Thread.isMainThread || AsyncAwait.isTesting else {
            fatalError("Await shall not be called on main thread.")
        }

        let timeout = _semaphore.wait(timeout: .now() + timeoutInterval)

        if case .timedOut = timeout {
            throw AwaitError.timedOut
        } else if let error = error {
            throw error
        } else if value == nil {
            throw AwaitError.nilValue
        }

        return value!
    }

}